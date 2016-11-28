;Wenn quicklisp nicht installiert
(load (merge-pathnames "quicklisp" (current-pathname)))
(ignore-errors(quicklisp-quickstart:install))

    
(load #P"~/quicklisp/setup.lisp")
(pushnew "../registry/" asdf:*central-registry* :test #'equal)

(defun load-util ()
  (load (current-pathname "util/util" "asd"))
  (ql:quickload :util ))

;;General setup methods
(defun load-articlereader ()
  (load (current-pathname "articlereader/articlereader" "asd"))
  (ql:quickload :articlereader ))


(defun load-indexer ()
  (load (current-pathname "indexer/indexer" "asd"))
  (ql:quickload :indexer ))

(defun load-classificator ()
  (load (current-pathname "classificator/classificator" "asd"))
  (ql:quickload :classificator))


(defun load-data ()
  (load (current-pathname "data/data" "asd"))
  (ql:quickload :data))

(defun load-gui ()
  (load (current-pathname "gui/gui" "asd"))
  (ql:quickload :gui))

(defun load-trivial-browser()
   (load (current-pathname "trivial-open-browser/trivial-open-browser" "asd"))
  (ql:quickload :trivial-open-browser))

;general setup
(defun setup (&key install-quicklisp)
   ;Wenn quicklisp nicht installiert
   ;(if install-quicklisp (progn (load (merge-pathnames "quicklisp" (current-pathname)))
    ;                       (ignore-errors(quicklisp-quickstart:install))))
  (load #P"~/quicklisp/setup.lisp")
  (pushnew "../registry/" asdf:*central-registry* :test #'equal)

  (load-util)
  (load-articlereader)
  (load (current-pathname "website-crawler/new_iis_start_small"))
  (load-indexer)
  (load-classificator)
  (load-data)
  (ignore-errors (ql:quickload :uiop))
  (ignore-errors (load-trivial-browser))
  (load-gui)
)

(setup)

;ben�tigtes setup
(load-trivial-browser)
(trivial-open-browser:open-browser "https://www.spiegel.de")

(data:read-categories (current-pathname "../data/categories" "txt"))

(data:read-page-structures (current-pathname "../data/pagestructure" "txt"))
(data:get-pagestructure-types)
(data:get-pagestructure "spiegel")


(data:get-category-name 1)

(data:read-links (current-pathname "../data/spiegel-data" "txt"))


(data:read-structures (current-pathname "../data/structure" "txt"))

(first (data:get-struct "sueddeutsche"))


(data:set-webfetcher (defun webfetcher (link)
  (webengine++lisp-webfetcher 0 link :want-string T)
))

;eventuell classificator speichern?
(data:build-classificator (current-pathname "../data/categories" "txt") (current-pathname "../data/structure" "txt") (list (current-pathname "../data/spiegel-data" "txt")))

(mapcar (lambda (tuple) 
          (list (first tuple) (get (get (first tuple) 'INDEXER:DOCUMENT) 'ARTICLEREADER:HEADLINE) (second tuple))
) (data:test-classificator))

(load-gui)
(gui:set-categories (mapcar 'second (data:get-categories)))
(gui:set-classes (mapcar 'second (get (classificator:get-corpus) 'CLASSIFICATOR:CLASSES)))
(gui:define-interface)


(setq *source-pages* '(("spiegel" "http://www.spiegel.de/politik/deutschland" "http://www.spiegel.de") ("sueddeutsche" "http://www.sueddeutsche.de/politik" "")))

(gui:set-search-function (lambda (term categories) 
                  (mapcan (lambda (source) (let* ((struct (data:get-pagestructure source))
                                                        (pagelink (second (find source *source-pages* :key #'first :test #'string-equal)))
                                                        (prefix (nth 2 (find source *source-pages* :key #'first :test #'string-equal)))
                                                        (article (articlereader:fetch-article (webengine++lisp-webfetcher 0 pagelink :want-string T) struct '()))
                                                        (teasers (remove-if (lambda (elem) (equal elem :TEASER)) (get article 'ARTICLEREADER:TEASERS))))
(mapcan (lambda (teaser) 

          
          (let* ((tarticle (articlereader:fetch-article (webengine++lisp-webfetcher 0 (concatenate 'string prefix teaser) :want-string T) (first (data:get-struct source)) (second (data:get-struct source))))
                (class  (classificator:classify-document  (indexer:make-index tarticle)))
                (class-name (first (first class)))
                (class-value (second class)))
                 (cond ((and categories (member class-name categories) (<= class-value -0.015) )                                          
                             (list (list (get tarticle 'ARTICLEREADER:HEADLINE) class-name class-value (concatenate 'string prefix teaser))))
                       ((and (not categories) (<= class-value -0.015))  (list (list (get tarticle 'ARTICLEREADER:HEADLINE) class-name class-value (concatenate 'string prefix teaser))))
                       ((not categories) (list (list (get tarticle 'ARTICLEREADER:HEADLINE) "" 0 (concatenate 'string prefix teaser))))
                       (T NIL))
                                                                       )) teasers)        
                                             )) (data:get-pagestructure-types))
                  

))


(gui:display)

;Drakma needs openSSl 1.0.1, the version 1.1.0 removed to much functionality


(setf *html-page* (webengine++lisp-webfetcher 0 "http://www.sueddeutsche.de/politik/bundesregierung-falsche-richtung-spd-1.3154952" :want-string T))

(setf *html-page2* (webengine++lisp-webfetcher 0 "http://www.sueddeutsche.de/politik/rechtsextremismus-neonazis-besitzen-schusswaffen-1.2895449" :want-string T))

;(:DIV ((:CLASS "header")) ("8. September 2016, 12:54 Uhr" (:H2 NIL ((:STRONG NIL ("T�rkei")) "T�rkei erlaubt Bundestagsabgeordneten Reise nach Incirlik"))))

(setf *sued-structure*
      '(:SEQUENCE (:DIV ((:CLASS "header")) (:SEQUENCE (:DIV ((:DATETIME :DATE) (:CLASS "timeformat"))) (:H2 NIL (:SEQUENCE :IGNORE :HEADLINE))))
        (:DIV ((:CLASS "body") (:ID "article-body")) (:PARALLEL (:P NIL :TEXT)))))

(setf *sued-link-structure* '((:A ((:DATA-PAGETYPE "THEME") (:CLASS "themelink")) (:SEQUENCE :TEXT))))



(setf article (articlereader:fetch-article *html-page* *sued-structure* *sued-link-structure*))


(setf article2 (articlereader:fetch-article *html-page2* *sued-structure* *sued-link-structure*))


(setf index (indexer:make-index article))

(setf index2 (indexer:make-index article2))



(load-classificator)

(classificator:setup)
(setq testclass (classificator:new-document-class "test"))
(setq testclass2 (classificator:new-document-class "test2"))

;classificator tests
(classificator:add-document testclass index)

(classificator:add-document testclass2 index2)




(classificator:calculate-corpus-metrics)

(classificator:classify-document index2)




(setf *html-page* (webengine++lisp-webfetcher 0 "http://www.spiegel.de/wirtschaft/soziales/fluechtlinge-in-deutschland-sind-oft-ueberqualifiziert-a-1111237.html" :want-string T))

(setf *spon-politik-deutsch* (webengine++lisp-webfetcher 0 "http://www.spiegel.de/politik/deutschland/" :want-string T))

(setf *spon-structure*
      '(:SEQUENCE (:SPAN ((:CLASS "headline-intro")) :HEADLINE-INTRO)
        (:SPAN ((:CLASS "headline")) :HEADLINE)
        (:P ((:CLASS "article-intro")) (:SEQUENCE (:STRONG NIL :TEXT)));:ARTICLE-INTRO)))
        (:DIV ((:CLASS "timeformat") (:ITEMPROP "datePublished") (:DATETIME :DATE)) ()); (:SEQUENCE (:SPAN ((:CLASS "article-function-date")) (:SEQUENCE :IGNORE :DATE :IGNORE)))) 
        
        (:DIV ((:CLASS "article-section clearfix") (:ITEMPROP "articleBody")) (:PARALLEL (:P NIL :TEXT))))
)

;#content-main
;(setf *spon-category-structure*
 ;     '(:SEQUENCE (:DIV ((:ID "content-main") (:CLASS "grid-channel spSmallScreen clearfix"))  
  ;                      (:PARALLEL (:DIV ((:CLASS "column-both")) (:PARALLEL (:DIV ((:CLASS "teaser teaser-first")) (:PARALLEL (:H2 ((:CLASS "article-title ")) :TEASER)))))))
   ;               (:DIV ((:CLASS "column-both main-content")) 
    ;                    (:PARALLEL (:DIV ((:CLASS "teaser teaser-first")) (:SEQUENCE (:DIV ((:CLASS "clearfix")) (:PARALLEL (:H2 ((:CLASS "article-title ")) :TEASER)))))
     ;                              (:DIV ((:CLASS "teaser")) (:SEQUENCE (:DIV ((:CLASS "clearfix")) (:PARALLEL (:H2 ((:CLASS "article-title ")) :TEASER)))))))))


(setf *spon-category-structure*
      '(:SEQUENCE (:DIV ((:ID "content-main") (:CLASS "grid-channel spSmallScreen clearfix"))  
                        (:PARALLEL (:DIV ((:CLASS "column-both")) (:PARALLEL (:DIV ((:CLASS "teaser teaser-first")) (:PARALLEL (:H2 ((:CLASS "article-title ")) (:PARALLEL (:A ((:ID :TEASER) (:TITLE :IGNORE)) NIL)))))))))
                  (:DIV ((:CLASS "column-both main-content")) 
                        (:PARALLEL (:DIV ((:CLASS "teaser teaser-first")) (:SEQUENCE (:DIV ((:CLASS "clearfix")) (:PARALLEL (:H2 ((:CLASS "article-title ")) (:PARALLEL (:A ((:ID :TEASER) (:TITLE :IGNORE)) NIL)))))))
                                   (:DIV ((:CLASS "teaser")) (:SEQUENCE (:DIV ((:CLASS "clearfix")) (:PARALLEL (:H2 ((:CLASS "article-title ")) (:PARALLEL (:A ((:ID :TEASER) (:TITLE :IGNORE)) NIL)))))))))))


(articlereader:parse-html *html-page*)

(articlereader:fetch-article *spon-politik-deutsch* *spon-category-structure* '())


(load-articlereader)
(articlereader:fetch-article *html-page* *spon-structure* '())


(setf *sueddeutsche-politik* (webengine++lisp-webfetcher 0 "http://www.sueddeutsche.de/politik" :want-string T))

;(setf *sueddeutsche-category-structure*
 ;     '(:SEQUENCE (:DIV ((:ID "wrapper"))
  ;                      (:PARALLEL (:DIV ((:ID "sitecontent")(:CLASS "mainpage")(:ROLE "main")) (:PARALLEL (:DIV ((:CLASS "teaser toptop")) :TEASER) (:DIV ((:CLASS "teaser top")) :TEASER)))))))

(setf *sueddeutsche-category-structure*
      '(:SEQUENCE (:DIV ((:ID "wrapper"))
                        (:PARALLEL (:DIV ((:ID "sitecontent")(:CLASS "mainpage")(:ROLE "main")) (:PARALLEL (:DIV ((:CLASS "teaser toptop")) (:PARALLEL (:A ((:ID :TEASER) (:CLASS "entry-title") (:REL "bookmark") (:DATA-PAGETYPE "STANDARD_ARTICLE") (:DATA-ID :IGNORE)) ()))) (:DIV ((:CLASS "teaser top")) (:PARALLEL (:A ((:ID :TEASER) (:CLASS "entry-title") (:REL "bookmark") (:DATA-PAGETYPE "STANDARD_ARTICLE") (:DATA-ID :IGNORE)) ())))))))))
                 ; (:DIV ((:CLASS "column-both main-content")) 
                  ;      (:PARALLEL (:DIV ((:CLASS "teaser teaser-first")) (:SEQUENCE (:DIV ((:CLASS "clearfix")) (:PARALLEL (:H2 ((:CLASS "article-title ")) :TEASER)))))
                   ;                (:DIV ((:CLASS "teaser")) (:SEQUENCE (:DIV ((:CLASS "clearfix")) (:PARALLEL (:H2 ((:CLASS "article-title ")) :TEASER)))))))))

(articlereader:fetch-article *sueddeutsche-politik* *sueddeutsche-category-structure* '())