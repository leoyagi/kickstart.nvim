;; extends

(macro_invocation
  macro: [
    (scoped_identifier 
      path: (_) @_macro_path 
      name: (_) @_macro_name)
    (identifier) @_macro_name
  ] 
  (token_tree) @injection.content
  (#eq? @_macro_path "leptos")
  (#eq? @_macro_name "view")
  (#set! injection.language "html")
  (#set! injection.include-children)
)
