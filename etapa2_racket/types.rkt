#lang typed/racket

(provide (all-defined-out))

(define-type (LazyStream A) (U Null (StreamNode A)))

(struct (A) StreamNode
  ([first : A]
   [rest : (Promise (LazyStream A))])
  #:transparent)

(struct ScheduleBlock
  ([day : Integer]
   [start-time : Integer]
   [end-time : Integer])
  #:transparent)

(struct Group
  ([group-number : Integer]
   [has-clash : Boolean]
   [schedules : (Listof ScheduleBlock)])
  #:transparent)

(struct Course
  ([code : String]
   [name : String]
   [career : String]
   [credits : Integer]
   [semester : Integer]
   [is-approved : Boolean]
   [is-eligible : Boolean]
   [has-any-schedule-clash : Boolean]
   [prerequisites : (Listof String)]
   [corequisites : (Listof String)]
   [groups : (Listof Group)])
  #:transparent)

(struct InterestedCourse
  ([code : String]
   [career : String]
   [groups : (Listof Integer)])
  #:transparent)

(struct Preferences
  ([min-credits : Integer]
   [max-credits : Integer]
   [interested-courses : (Listof InterestedCourse)])
  #:transparent)

(struct SelectedGroup
  ([code : String]
   [name : String]
   [career : String]
   [credits : Integer]
   [group-number : Integer]
   [has-clash : Boolean]
   [schedules : (Listof ScheduleBlock)])
  #:transparent)

(struct ScheduleCombination
  ([selections : (Listof SelectedGroup)]
   [total-credits : Integer])
  #:transparent)