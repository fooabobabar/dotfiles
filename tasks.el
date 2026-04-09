(defun tasks-new-huid ()
  (format-time-string "%Y%m%d-%H%M%S"))

(defun tasks-find-database ()
  (let ((dir default-directory))
    (catch 'result
      (while dir
        (let ((db-dir (file-name-concat dir "tasks")))
          (if (file-directory-p db-dir)
              (throw 'result db-dir)
            (setq dir (file-name-parent-directory dir))))))))

(defun tasks-create-from-todo ()
  (interactive)
  (let ((line (thing-at-point 'line)))
    (when (string-match "\\(.*\\)TODO:\\(.*\\)" line)
      (let ((prefix (match-string 1 line))
            (suffix (string-trim (match-string 2 line))))
        (let ((db-dir (tasks-find-database)))
          (when db-dir
            (let* ((huid (tasks-new-huid))
                   (task-path (file-name-concat db-dir huid)))
              (if (file-exists-p task-path)
                  (message "ERROR: %s already exists. Trying again later." task-path)
                (delete-line)
                (insert (format "%sTASK(%s): %s\n" prefix (tasks-new-huid) suffix))
                (mkdir task-path)
                (let ((task-md-path (file-name-concat task-path "TASK.md")))
                  (write-region
                   (format (concat "# %s\n"
                                   "\n"
                                   "- STATUS: OPEN\n"
                                   "- PRIORITY: 50\n")
                           suffix)
                   nil
                   task-md-path)
                  (find-file-other-window task-md-path))))))))))

(defun tasks-find-by-huid ()
  (interactive)
  (let ((huid
         (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           (completing-read "HUID: " nil)))
        (db-dir (tasks-find-database)))
    (if (not-db-dir) (message "Tasks database was not found")
      (let ((task-md-path (file-name-concat db-dir huid "TASK.md")))
        (if (not (file-regular-p task-md-path)) (message "Task %s was not found" huid)
          (find-file-other-window task-md-path))))))
