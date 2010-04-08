;; this is a collection of utility functions and macros
;; for euslisp coordination system interface and 
;; ros coordination system interface

;; include ros messages packages
(roseus-add-msgs "roslib")
(roseus-add-msgs "std_msgs")
(roseus-add-msgs "roseus")
(roseus-add-msgs "nav_msgs")
(roseus-add-msgs "geometry_msgs") ;move_base_msgs depends on geometry_msgs

;; convert unit....
;; eus [mm], ros[m]
(defun coords->geometry-msgs-pose (coords)
  (let ((x (* 0.001 (x (send coords :worldpos)))) ;mm -> m
        (y (* 0.001 (y (send coords :worldpos)))) ;mm -> m
        (z (* 0.001 (z (send coords :worldpos)))) ;mm -> m
        (rot (send coords :worldrot)))
    (let ((q (matrix2quaternion rot)))
      (let ((qx (elt q 0))
            (qy (elt q 1))
            (qz (elt q 2))
            (qw (elt q 3)))
        (instance geometry_msgs::pose :init 
                  :position (instance geometry_msgs::point :init :x x :y y :z z)
                  :orientation
                  (instance geometry_msgs::quaternion :init :x qx :y qy :z qz :w qw))))))

(defun geometry-msgs-pose->coords (pose)
  (let ((position (send pose :position))
        (orientation (send pose :orientation)))
    (let ((x (* 1000.0 (send position :x))) ;m -> mm
          (y (* 1000.0 (send position :y))) ;m -> mm
          (z (* 1000.0 (send position :z))) ;m -> mm
          (q (float-vector (send orientation :x)
                           (send orientation :y)
                           (send orientation :z)
                           (send orientation :w))))
    (make-coords :pos (float-vector x y z)
                 :rot (quaternion2matrix q)))))

(defun coords->geometry-msgs-stamped-pose (coords id)
  (let ((pose (coords->geometry-msgs-pose coords)))
    ;; PoseStamped = Header + Pose
    ;; Header = seq + frame_id
    (instance geometry_msgs::PoseStamped :init
              :header (instance roslib::header :init :frame_id id)
              :pose pose)))

(defun nav-msgs-odometry->coords (odom)
  ;; NB: does not consider about frame_id
  ;; NB: coordinates is projected x-y plane.
  ;; Odometry = Header:header + string:child_frame_id
  ;;                          + geometry_msgs/PoseWithCovariance:pose
  ;;                          + geometry_msgs/TwistWithCovariance:twist
  (geometry-msgs-pose->coords (send (send odom :pose) :pose)))

(defun geometry-msgs-transform->coords (pose)
  (let ((position (send pose :ranslation))
        (orientation (send pose :rotation)))
    (let ((x (* 1000.0 (send position :x))) ;m -> mm
          (y (* 1000.0 (send position :y))) ;m -> mm
          (z (* 1000.0 (send position :z))) ;m -> mm
          (q (float-vector (send orientation :w)
                           (send orientation :x)
                           (send orientation :y)
                           (send orientation :z))))
    (make-coords :pos (float-vector x y z)
                 :rot (quaternion2matrix q)))))