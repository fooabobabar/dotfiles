;;; translator.el --- AI-powered translation via Claude or Ollama -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: Lucas
;; Maintainer: Lucas
;; Version: 2.0.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, i18n, translation, tools
;; URL: https://example.com/translator

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; translator.el translates the selected text using either the Anthropic
;; Claude Messages API or a local Ollama server, and shows the plain
;; translation in a new buffer.  It is a single, self-contained file that
;; depends only on Emacs built-ins (`url.el' and `json.el').
;;
;; The primary direction is any language -> Brazilian Portuguese (pt-BR);
;; a second command translates Brazilian Portuguese -> English.
;;
;; Commands
;; --------
;; * `translator-translate-region'     Translate the region into pt-BR.
;; * `translator-translate-ptbr-to-en' Translate the region (assumed to be
;;                                     Brazilian Portuguese) into English.
;;
;; Both open the translation in a new buffer; the source buffer is not
;; modified.
;;
;; Setup (Anthropic, the default provider)
;; ----------------------------------------
;;   (load "~/.emacs.local/translator.el")
;;   (setq translator-anthropic-api-key "YOUR_KEY")
;;
;; The API key is also read from the ANTHROPIC_API_KEY environment
;; variable or from `auth-source' (host "api.anthropic.com").
;;
;; Setup (Ollama, a local server)
;; ------------------------------
;;   (setq translator-provider 'ollama
;;         translator-ollama-model "llama3.1")
;;
;; Notes
;; -----
;; Some recent Claude models reject the `temperature' parameter.
;; `translator-temperature' is therefore nil by default and is only sent
;; (to whichever provider) when set to a number.

;;; Code:

(require 'url)
(require 'json)
(require 'subr-x)


;;;; Customization

(defgroup translator nil
  "AI-powered translation using the Anthropic Claude API or Ollama."
  :group 'tools
  :prefix "translator-")

(defcustom translator-provider 'anthropic
  "LLM provider used for translation.
Either `anthropic' (the Claude Messages API, requires an API key) or
`ollama' (a local Ollama server, no API key required)."
  :type '(choice (const :tag "Anthropic Claude" anthropic)
                 (const :tag "Ollama (local)" ollama))
  :group 'translator)

(defcustom translator-anthropic-api-key nil
  "Anthropic API key used to authenticate requests.
When nil, the key is looked up in the ANTHROPIC_API_KEY environment
variable and then in `auth-source' for host \"api.anthropic.com\"."
  :type '(choice (const :tag "Look up elsewhere" nil)
                 (string :tag "API key"))
  :group 'translator)

(defcustom translator-model "claude-haiku-4-5"
  "Claude model used for translation when `translator-provider' is `anthropic'.
For Ollama, set `translator-ollama-model' instead."
  :type 'string
  :group 'translator)

(defcustom translator-max-tokens 4096
  "Maximum number of tokens the model may generate for a translation."
  :type 'integer
  :group 'translator)

(defcustom translator-temperature nil
  "Sampling temperature for the model, or nil to use the model default.
Only sent to the provider when it is a number.  Some recent Claude models
reject this parameter, so leave it nil unless you also select a model that
accepts sampling parameters."
  :type '(choice (const :tag "Model default" nil)
                 (number :tag "Temperature"))
  :group 'translator)

(defcustom translator-request-timeout 60
  "Number of seconds to wait for the provider before giving up."
  :type 'number
  :group 'translator)

(defcustom translator-api-url "https://api.anthropic.com/v1/messages"
  "Endpoint for the Anthropic Messages API."
  :type 'string
  :group 'translator)

(defcustom translator-api-version "2023-06-01"
  "Value of the `anthropic-version' HTTP header."
  :type 'string
  :group 'translator)

(defcustom translator-ollama-api-url "http://localhost:11434/api/chat"
  "Endpoint for the Ollama chat API.
Used when `translator-provider' is `ollama'."
  :type 'string
  :group 'translator)

(defcustom translator-ollama-model "llama3.1"
  "Name of the model served by Ollama, e.g. \"llama3.1\" or \"qwen2.5\".
Used when `translator-provider' is `ollama'.  The model must already be
available on the server (\"ollama pull <model>\")."
  :type 'string
  :group 'translator)


;;;; Prompts

(defconst translator-region-system-prompt
  "You are a professional translator.  Detect the source language of the \
text and translate it into natural, fluent Brazilian Portuguese (pt-BR).

Return ONLY the translation, with no commentary, explanations, notes, \
labels, or surrounding quotation marks.  Never translate source code, \
identifiers, or commands.  If the text is already in Brazilian \
Portuguese, return it unchanged."
  "System prompt for translating text into pt-BR.")

(defconst translator-ptbr-en-system-prompt
  "You are a professional translator.  The text is written in Brazilian \
Portuguese.  Translate it into natural, fluent English.

Return ONLY the translation, with no commentary, explanations, notes, \
labels, or surrounding quotation marks.  Never translate source code, \
identifiers, or commands."
  "System prompt for translating pt-BR text into English.")


;;;; API client

(defun translator--api-key ()
  "Return the Anthropic API key, or signal a user error if none is found."
  (or translator-anthropic-api-key
      (getenv "ANTHROPIC_API_KEY")
      (when (require 'auth-source nil t)
        (when-let* ((entry (car (auth-source-search
                                 :host "api.anthropic.com" :max 1)))
                    (secret (plist-get entry :secret)))
          (if (functionp secret) (funcall secret) secret)))
      (user-error
       "Translator: set `translator-anthropic-api-key' (or ANTHROPIC_API_KEY)")))

(defun translator--anthropic-body (text system-prompt)
  "Return the Anthropic JSON body translating TEXT with SYSTEM-PROMPT."
  (let ((params `((model . ,translator-model)
                  (max_tokens . ,translator-max-tokens)
                  (system . ,system-prompt)
                  (messages . [((role . "user") (content . ,text))]))))
    ;; Only send `temperature' when explicitly configured: recent models
    ;; reject it and return HTTP 400.
    (when (numberp translator-temperature)
      (setq params (append params `((temperature . ,translator-temperature)))))
    (json-encode params)))

(defun translator--ollama-body (text system-prompt)
  "Return the Ollama JSON body translating TEXT with SYSTEM-PROMPT."
  (let ((options `((num_predict . ,translator-max-tokens))))
    (when (numberp translator-temperature)
      (setq options (append options `((temperature . ,translator-temperature)))))
    (json-encode
     `((model . ,translator-ollama-model)
       (stream . :json-false)
       (options . ,options)
       (messages . [((role . "system") (content . ,system-prompt))
                    ((role . "user") (content . ,text))])))))

(defun translator--build-request (text system-prompt)
  "Return a plist (:url :headers :data) for the active provider.
Translates TEXT with SYSTEM-PROMPT.  May signal a `user-error' (e.g. a
missing Anthropic API key)."
  (pcase translator-provider
    ('anthropic
     (list :url translator-api-url
           :headers (list (cons "content-type" "application/json")
                          (cons "x-api-key" (translator--api-key))
                          (cons "anthropic-version" translator-api-version))
           :data (translator--anthropic-body text system-prompt)))
    ('ollama
     (list :url translator-ollama-api-url
           :headers (list (cons "content-type" "application/json"))
           :data (translator--ollama-body text system-prompt)))
    (_ (user-error "Translator: unknown provider `%s'" translator-provider))))

(defun translator--decode-json (string)
  "Parse STRING as JSON into an alist, or return nil on failure."
  (let ((json-object-type 'alist)
        (json-array-type 'vector)
        (json-key-type 'symbol)
        (json-false nil)
        (json-null nil))
    (json-read-from-string string)))

(defun translator--read-response ()
  "Parse the current `url' response buffer.
Return a cons cell (STATUS-CODE . BODY-STRING).  STATUS-CODE may be nil
if it cannot be determined.  BODY-STRING is decoded as UTF-8."
  (goto-char (point-min))
  (let ((code (when (re-search-forward "\\`HTTP/[0-9.]+ +\\([0-9]+\\)" nil t)
                (string-to-number (match-string 1)))))
    (goto-char (point-min))
    (let ((body (if (re-search-forward "\r?\n\r?\n" nil t)
                    (buffer-substring-no-properties (point) (point-max))
                  (buffer-string))))
      (cons code (decode-coding-string body 'utf-8)))))

(defun translator--error-string (code type message)
  "Return a friendly error string from CODE, error TYPE and MESSAGE."
  (cond
   (message (format "API error%s: %s"
                    (if code (format " (%s)" code) "")
                    message))
   ((eq code 401) "Invalid or missing API key (401)")
   ((eq code 403) "Permission denied for this key or model (403)")
   ((eq code 404) "Not found — check the model name (404)")
   ((eq code 413) "Request too large (413) — try a smaller selection")
   ((eq code 429) "Rate limited (429) — please retry shortly")
   ((and code (>= code 500)) (format "Server error (%s) — retry later" code))
   (code (format "Unexpected API error (%s)%s" code
                 (if type (format ": %s" type) "")))
   (t "Unknown API error")))

(defun translator--anthropic-interpret (code data callback)
  "Interpret an Anthropic response (HTTP CODE, parsed DATA); invoke CALLBACK."
  (cond
   ((and (consp data) (equal (alist-get 'type data) "error"))
    (let ((e (alist-get 'error data)))
      (funcall callback nil
               (translator--error-string code
                                          (alist-get 'type e)
                                          (alist-get 'message e)))))
   ((and code (>= code 400))
    (funcall callback nil (translator--error-string code nil nil)))
   ((null data)
    (funcall callback nil "Malformed response from the API"))
   (t
    (let* ((content (alist-get 'content data))
           (text (and (vectorp content) (> (length content) 0)
                      (alist-get 'text (aref content 0)))))
      (if (stringp text)
          (funcall callback (string-trim text) nil)
        (funcall callback nil "No translation returned"))))))

(defun translator--ollama-interpret (code data callback)
  "Interpret an Ollama response (HTTP CODE, parsed DATA); invoke CALLBACK."
  (cond
   ((and (consp data) (stringp (alist-get 'error data)))
    (funcall callback nil
             (translator--error-string code "ollama_error"
                                        (alist-get 'error data))))
   ((and code (>= code 400))
    (funcall callback nil (translator--error-string code nil nil)))
   ((null data)
    (funcall callback nil "Malformed response from Ollama"))
   (t
    (let* ((message (alist-get 'message data))
           (text (and (consp message) (alist-get 'content message))))
      (if (stringp text)
          (funcall callback (string-trim text) nil)
        (funcall callback nil "No translation returned"))))))

(defun translator--interpret (code body callback)
  "Interpret HTTP CODE and BODY for the active provider, then invoke CALLBACK.
CALLBACK is called with two arguments (TEXT ERROR): exactly one is
non-nil."
  (let ((data (ignore-errors (translator--decode-json body))))
    (pcase translator-provider
      ('anthropic (translator--anthropic-interpret code data callback))
      ('ollama (translator--ollama-interpret code data callback))
      (_ (funcall callback nil
                  (format "Unknown provider `%s'" translator-provider))))))

(defun translator--network-error-string (status)
  "Return a friendly message for a transport-level STATUS error."
  (format "Network error: %s%s"
          (error-message-string (plist-get status :error))
          (if (eq translator-provider 'ollama)
              " (is the Ollama server running?)"
            "")))

(defun translator--dispatch (status callback)
  "Handle url STATUS in the response buffer and invoke CALLBACK.
`url.el' flags any non-2xx HTTP response via STATUS `:error', but the
response body is still present.  So whenever a status line is found the
body is parsed and passed to `translator--interpret', which surfaces the
provider's own error message; STATUS `:error' is only used as a fallback
for genuine transport failures with no HTTP response."
  (condition-case err
      (pcase-let ((`(,code . ,body) (translator--read-response)))
        (cond
         (code (translator--interpret code body callback))
         ((plist-get status :error)
          (funcall callback nil (translator--network-error-string status)))
         (t (funcall callback nil "Empty response from the server"))))
    (error (funcall callback nil
                    (format "Failed to read response: %s"
                            (error-message-string err))))))

(defun translator--post (text system-prompt callback)
  "Translate TEXT using SYSTEM-PROMPT asynchronously.
CALLBACK is invoked with (RESULT ERROR); exactly one is non-nil.  Emacs
is never blocked while the request is in flight."
  (let* ((request (translator--build-request text system-prompt))
         (url (plist-get request :url))
         (url-request-method "POST")
         (url-request-extra-headers (plist-get request :headers))
         (url-request-data
          (encode-coding-string (plist-get request :data) 'utf-8))
         (done nil)
         (timer nil))
    (message "Translating…")
    (setq timer
          (run-with-timer
           translator-request-timeout nil
           (lambda ()
             (unless done
               (setq done t)
               (funcall callback nil
                        (format "Request timed out after %ss"
                                translator-request-timeout))))))
    (condition-case err
        (url-retrieve
         url
         (lambda (status)
           (let ((buf (current-buffer)))
             (unwind-protect
                 (unless done
                   (setq done t)
                   (when (timerp timer) (cancel-timer timer))
                   (translator--dispatch status callback))
               (when (buffer-live-p buf) (kill-buffer buf)))))
         nil t t)
      (error
       (unless done
         (setq done t)
         (when (timerp timer) (cancel-timer timer))
         (funcall callback nil
                  (format "Could not start request: %s"
                          (error-message-string err))))))))


;;;; Translation

(defun translator--show (result)
  "Display RESULT, the translated text, in a new read-only buffer."
  (let ((buf (generate-new-buffer "*Translation*")))
    (with-current-buffer buf
      (insert (string-trim result))
      (goto-char (point-min))
      (set-buffer-modified-p nil)
      (view-mode 1))
    (pop-to-buffer buf)))

(defun translator--translate (text system-prompt)
  "Translate TEXT with SYSTEM-PROMPT and show the result in a new buffer.
Runs asynchronously; errors are reported in the echo area."
  (translator--post
   text system-prompt
   (lambda (result err)
     (if err
         (message "Translator: %s" err)
       (translator--show result)))))


;;;; Interactive commands

;;;###autoload
(defun translator-translate-region (beg end)
  "Translate the region between BEG and END into Brazilian Portuguese.
The source language is detected automatically and the translation is
shown in a new buffer; the current buffer is not modified."
  (interactive "r")
  (unless (use-region-p)
    (user-error "No active region to translate"))
  (translator--translate (buffer-substring-no-properties beg end)
                         translator-region-system-prompt))

;;;###autoload
(define-obsolete-function-alias 'translator-popup-translate
  #'translator-translate-region "2.0.0")

;;;###autoload
(defun translator-translate-ptbr-to-en (beg end)
  "Translate the region between BEG and END from pt-BR into English.
The region text is assumed to be Brazilian Portuguese and the translation
is shown in a new buffer; the current buffer is not modified."
  (interactive "r")
  (unless (use-region-p)
    (user-error "No active region to translate"))
  (translator--translate (buffer-substring-no-properties beg end)
                         translator-ptbr-en-system-prompt))

(provide 'translator)

;;; translator.el ends here
