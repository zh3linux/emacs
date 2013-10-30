(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector [default bold shadow italic underline bold bold-italic bold])
 '(ansi-color-names-vector (vector "#657b83" "#dc322f" "#859900" "#b58900" "#268bd2" "#d33682" "#2aa198" "#fdf6e3"))
 '(custom-enabled-themes (quote (tsdh-dark)))
 '(custom-safe-themes (quote ("4cf3221feff536e2b3385209e9b9dc4c2e0818a69a1cdb4b522756bcdf4e00a4" default)))
 '(fci-rule-color "#eee8d5")
 '(session-use-package t nil (session))
 '(vc-annotate-background nil)
 '(vc-annotate-color-map (quote ((20 . "#dc322f") (40 . "#cb4b16") (60 . "#b58900") (80 . "#859900") (100 . "#2aa198") (120 . "#268bd2") (140 . "#d33682") (160 . "#6c71c4") (180 . "#dc322f") (200 . "#cb4b16") (220 . "#b58900") (240 . "#859900") (260 . "#2aa198") (280 . "#268bd2") (300 . "#d33682") (320 . "#6c71c4") (340 . "#dc322f") (360 . "#cb4b16"))))
 '(vc-annotate-very-old-color nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(setq default-tab-width 4)
(setq tab-width 4)
(setq lua-indent-level 4)
(defun my-lua-setup ()
  (setq indent-tabs-mode nil))
(add-hook 'lua-mode-hook 'my-lua-setup)
(set-default-font "-microsoft-YaHei Consolas Hybrid-normal-normal-normal-*-17-*-*-*-*-0-iso10646-1")
(setq scroll-margin 1
      scroll-conservatively 10000);;防止页面滚动时跳动
(require 'popwin)
(popwin-mode 1)

(require 'direx)
(push '(direx:direx-mode :position left :width 25 :dedicated t)
      popwin:special-display-config)
(global-set-key (kbd "C-x C-j") 'direx:jump-to-directory-other-window)
(setq w3m-default-display-inline-images t)
(setq w3m-home-page "http://www.google.com")


;;----- weibo -----
(add-to-list 'load-path "weibo.emacs")
(require 'weibo)
;;===========================================================================
;;sr-speedbar-mode
;;===========================================================================
(require 'sr-speedbar)
;;默认显示所有文件
(custom-set-variables
 '(speedbar-show-unknown-files t)
)
;;sr-speedbar-right-side 把speedbar放在左侧位置
;;sr-speedbar-skip-other-window-p 多窗口切换时跳过speedbar窗口
;;sr-speedbar-max-width与sr-speedbar-width-x 设置宽度
;;(custom-set-variables '(sr-speedbar-right-side nil) '(sr-speedbar-skip-other-window-p t) '(sr-speedbar-max-width 20) '(sr-speedbar-width-x 10))
;; 绑定快捷键
;;(global-set-key (kbd "s-s") 'sr-speedbar-toggle)
;;(global-set-key (kbd "s-r") 'sr-speedbar-refresh-toggle)
;; 打开
;;(sr-speedbar-open)
