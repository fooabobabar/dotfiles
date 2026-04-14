;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(display-line-numbers-type 'relative)
 '(org-agenda-dim-blocked-tasks nil)
 '(org-agenda-exporter-settings '((org-agenda-tag-filter-preset (list "+personal"))))
 '(org-cliplink-transport-implementation 'url-el)
 '(org-enforce-todo-dependencies nil)
 '(org-modules
   '(org-bbdb org-bibtex org-docview org-gnus org-habit org-info org-irc
              org-mhe org-rmail org-w3m))
 '(org-refile-use-outline-path 'file)
 '(package-selected-packages
   '(cmake-mode company dash-functional docker-compose-mode
                dockerfile-mode ellama go-mode gruber-darker-theme
                helm-ls-git ido-completing-read+ lua-mode magit
                markdown-mode move-text multiple-cursors nginx-mode
                nim-mode org-cliplink paredit proof-general rust-mode
                smex tide toml-mode typescript-mode vterm yasnippet))
 '(safe-local-variable-values '((eval rc/autocommit-dir-locals)))
 '(warning-minimum-level :error)
 '(whitespace-style
   '(face tabs spaces trailing space-before-tab newline indentation empty
          space-after-tab space-mark tab-mark)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
