(in-package :cl-user)

(eval-when (compile load eval)
  (require :aserve)
  (require :ssl)
  (require :webactions)
  (require :datetime))

(defpackage "lkm-art-db"
  (:nicknames "art")
  (:use :common-lisp :excl :net.aserve.client :net.html.generator :net.aserve :multiprocessing))

(in-package :lkm-art-db) ;; include this at the top of subsequent files of CLP functions, etc.

;; starts allegroserve
(defun start-allegroserve (port)
  (net.aserve:start
   :port port
   :external-format (crlf-base-ef "utf-8")))

;; the destination is the location of the webui directory
(defun test-wa (destination)
  (webaction-project
   "lkm-art-db"
   :destination destination 
   :index "home"
   :project-prefix "/"
   :map '(("home" "index.clp")
          ("first-action-function" first-action-function first-view-function)
          ("first-action-function-xml" first-action-function first-view-function-xml)
          ("add-item" action-add-item "add-item.clp")
          ("add-item-submit" action-add-item-submit "view-items.clp" (:redirect t))
          ("view-items" "view-items.clp")
          ("view-item" "view-item.clp")
          ("edit-item" action-edit-item "edit-item.clp")
          ("edit-item-save" action-edit-item-save "view-items.clp" (:redirect t))
          ("delete-item" action-delete-item "view-items.clp" (:redirect t))))
  (load-db))

(defparameter *db-path* "P:/2Is Data/test-webserver/lkm-art-db/db/lkm-art.db")
(defparameter *art-items* ())

;;; an example of a CLP function
(def-clp-function art_test-clp (req ent args body)
  (declare (ignore req ent args body))
  (html (:princ-safe "This is the output of the CLP function.")))

;;; an example of an action function
(defun first-action-function (req ent)
  (declare (ignore req ent))
  :continue)

;;; displays the total number of items in the db
(def-clp-function art_item-count (req ent args body)
  (declare (ignore req ent args body))
  (html (:princ-safe (length *art-items*))))

;;; preps webserver to display add item page
(defun action-add-item (req ent)
  (declare (ignore req ent))
  (let ((websession (websession-from-req req)))
    (clear-curr-item websession))
  :continue)

;;; adds an item to the db
(defun action-add-item-submit (req ent)
  (declare (ignore req ent))
  (let ((uid (string (gensym)))
        (number (request-query-value "number" req))
        (title (request-query-value "title" req))
        (date (request-query-value "date" req))
        (size (request-query-value "size" req))
        (medium (request-query-value "medium" req))
        (price (request-query-value "price" req)))
    (push (list :uid uid :number number :title title :date date :size size :medium medium :price price) *art-items*)
    (save-db)
    :continue))

;;; stores the item to edit as the current item in the webession variable
(defun action-edit-item (req ent)
  (declare (ignore req ent))
  (let* ((uid (request-query-value "uid" req))
         (item (car (select-by-uid uid)))
         (websession (websession-from-req req)))
    (setf (websession-variable websession "curr-item") item))
  :continue)

;;; edits the current item in the webession variable in the db
;;; then clears the webession variable
(defun action-edit-item-save (req ent)
  (declare (ignore req ent))
  (let* ((websession (websession-from-req req))
         (uid (getf (websession-variable websession "curr-item") :uid))
         (new-number (request-query-value "number" req))
         (new-title (request-query-value "title" req))
         (new-date (request-query-value "date" req))
         (new-size (request-query-value "size" req))
         (new-medium (request-query-value "medium" req))
         (new-price (request-query-value "price" req)))
    (setf *art-items* (remove-if 
                       #'(lambda (item) (equal (getf item :uid) uid))
                       *art-items*))
    (push (list :uid uid :number new-number :title new-title :date new-date :size new-size :medium new-medium :price new-price) *art-items*)
    (save-db))
  :continue)

;;; clears the webession variable containing the current item
(defun clear-curr-item (websession)
  (setf (websession-variable websession "curr-item") nil))

;;; removes an item from the db
(defun action-delete-item (req ent)
  (declare (ignore req ent))
  (let* ((uid (request-query-value "uid" req))
         (item (car (select-by-uid uid))))
    (setf *art-items* (remove-if 
                       #'(lambda (item) (equal (getf item :uid) uid))
                       *art-items*)))
  (save-db)
  :continue)

;;; displays the property corresponding to the specified slot for the current item
(def-clp-function art_curr-item (req ent args body)
  (declare (ignore req ent args body))
  (let* ((slot (intern (cdar args) :keyword))
         (websession (websession-from-req req))
         (value (getf (websession-variable websession "curr-item") slot)))
    (if value
        (html (:princ-safe value))
      (html (:princ-safe "")))))

;; queries the db by uid
;; adapted from PCL Ch. 3
(defun select-by-uid (uid)
  (remove-if-not
   #'(lambda (item) (equal (getf item :uid) uid))
   *art-items*))

;; displays the list of all properties for a selected item
(def-clp-function art_view-item (req ent args body)
  (declare (ignore req ent am rgs body))
  (let* ((uid (request-query-value "uid" req))
         (item (car (select-by-uid uid))))
    (html
     ((:ul)
      (html ((:li) (:princ-safe (format nil "Number: ~a" (getf item :number))))
            ((:li) (:princ-safe (format nil "Title: ~a" (getf item :title))))
            ((:li) (:princ-safe (format nil "Date: ~a" (getf item :date))))
            ((:li) (:princ-safe (format nil "Size: ~a" (getf item :size))))
            ((:li) (:princ-safe (format nil "Medium: ~a" (getf item :medium))))
            ((:li) (:princ-safe (format nil "Price: ~a" (getf item :price))))
            ((:li) ((:a :href (format nil "edit-item?uid=~a" uid)) (:princ-safe "edit")))
            ((:li) ((:a :href (format nil "delete-item?uid=~a" uid)) (:princ-safe "delete"))))))))

;; displays a list of all items (and a summary of their properties)
(def-clp-function art_view-items (req ent args body)
  (declare (ignore req ent am rgs body))
  (if (eql (length *art-items*) 0)
      (html ((:p) (:princ-safe "There are no items in the database.")))
    (loop for i in *art-items*
        do
          (html
           ((:ul)
            (let ((uid (getf i :uid)))
              (html ((:li) (:princ-safe (format nil "Number: ~a" (getf i :number))))
                    ((:li) (:princ-safe (format nil "Title: ~a" (getf i :title))))
                    ((:li) (:princ-safe (format nil "Date: ~a" (getf i :date))))
                    ((:li) (:princ-safe (format nil "Size: ~a" (getf i :size))))
                    ((:li) (:princ-safe (format nil "Medium: ~a" (getf i :medium))))
                    ((:li) (:princ-safe (format nil "Price: ~a" (getf i :price))))
                    ((:li) ((:a :href (format nil "view-item?uid=~a" uid)) (:princ-safe "view details")))
                    ((:li) ((:a :href (format nil "edit-item?uid=~a" uid)) (:princ-safe "edit")))
                    ((:li) ((:a :href (format nil "delete-item?uid=~a" uid)) (:princ-safe "delete"))))))))))
      
;; an example of a view function that returns HTML
(defun first-view-function (req ent)
  (with-http-response (req ent :content-type "text\html")
    (with-http-body (req ent)
      (format *html-stream* "<p>This is HTML</p>"))) nil)

;; an example of a view function that returns XML
(defun first-view-function-xml (req ent)
  (with-http-response (req ent :content-type "text\xml")
    (with-http-body (req ent)
      (format *html-stream* "<response>This is xml</response>"))) nil)

;; starts the webserver
(defun start-ws ()
  (start-allegroserve 1990)
  (test-wa "P:\\2Is Data\\test-webserver\\lkm-art-db\\webui\\"))

;; saves the db of art items to a file
(defun save-db ()
  (with-open-file (out *db-path*
                       :direction :output
                       :if-exists :supersede)
    (with-standard-io-syntax
      (print *art-items* out))))

;; loads the db of art items from the file
(defun load-db ()
  (with-open-file (in *db-path*)
    (with-standard-io-syntax
      (setf *art-items* (read in)))))