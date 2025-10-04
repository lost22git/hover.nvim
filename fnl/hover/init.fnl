(fn disable_diagnostic [bufid]
  "Disable diagnostic for given buffer"
  (when (vim.diagnostic.is_enabled {:bufnr bufid})
    (pcall vim.diagnostic.enable false {:bufnr bufid})))

(fn open_hover_window [text_or_lines title callback]
  "Open hover window"
  ;; lines to put into buffer
  (local lines (case (type text_or_lines)
                 :string (vim.fn.split text_or_lines "\n" true)
                 _ text_or_lines))
  ;; calculate max columns of window
  (var max_cols 0)
  (each [_ l (ipairs lines)]
    (set max_cols (math.max max_cols (vim.api.nvim_strwidth l))))
  ;; create buffer and put lines
  (local bufid (vim.api.nvim_create_buf false true))
  (vim.api.nvim_buf_set_lines bufid 0 -1 false lines)
  ;; open float window to attach buffer
  (local winid (vim.api.nvim_open_win bufid true
                                      {:title title
                                       :relative :cursor
                                       :row 1
                                       :col 0
                                       :width max_cols
                                       :height (math.min 16 (length lines))
                                       :style :minimal}))
  ;; set some local options of buffer and window
  (disable_diagnostic bufid)
  (tset vim.bo bufid :readonly true)
  (tset vim.bo bufid :modifiable false)
  (tset vim.wo winid :wrap false)
  ;; call callback after window opened
  (when callback (callback bufid winid)))

(fn get_current_file []
  "Get current file"
  (vim.fn.expand "%"))

(fn get_cursor_location []
  "Get line number and column number under the cursor"
  (values (vim.fn.line ".") (vim.fn.col ".")))

(fn get_cursor_word []
  "Get a word under the cursor"
  (vim.fn.expand "<cword>"))

(fn get_selection_text []
  "Get current selection text"
  (vim.cmd "exe  \"normal \\<Esc>\"")
  (vim.cmd "normal! gv\"xy")
  (vim.fn.trim (vim.fn.getreg "x")))

(fn on_v_modes []
  "Check if on visual modes"
  (let [v_block_mode (vim.api.nvim_replace_termcodes :<C_V> true true true)
        v_modes [:v :V v_block_mode]]
    (vim.list_contains v_modes (vim.fn.mode))))

(fn get_cursor_text []
  "
  - On normal mode, we get cursor word
  - On visual mode, we get selection text
  "
  (case (on_v_modes)
    false (get_cursor_word)
    true (get_selection_text)))

(fn do_run [{: run}]
  (local (line_number column_number) (get_cursor_location))
  (run {:file (get_current_file)
        :line line_number
        :column column_number
        :text (get_cursor_text)
        :open_hover_window open_hover_window}))

(fn add_keymap [item bufid]
  (local {: name : key : mode} item)
  (vim.keymap.set mode key #(do_run item) {:buffer bufid :desc name}))

(fn create_autocmd [item]
  (local {: name : event : pattern} item)
  (vim.api.nvim_create_autocmd event
                               {:desc name
                                :pattern pattern
                                :callback (fn [{:buf bufid}]
                                            (add_keymap item bufid)
                                            nil)}))

(local M {})

;; Spec of each config item
;;
;; {:name "crystal tool expand"
;;  :event :FileType
;;  :pattern :crystal
;;  :key "<Leader>ke"
;;  :mode :n
;;  :run (fn [{: file : line : column : text : open_hover_window}]
;;          "")}

(fn M.setup [config]
  (local items (or (?. config :items) []))
  (each [_ item (ipairs items)]
    (create_autocmd item)))

M
