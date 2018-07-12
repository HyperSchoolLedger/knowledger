package main

type Institution struct {
	Name string 
	Address string
}

type School struct {
	Institution Institution
	Name string
	Address string
}

type Course struct {
	School School
	Name string
	Level Level
}

type Discipline struct {
	Course Course
	Name string
	Year int64
}

type Person struct {
	Name string 
	Birthday int64 /* epoch time */
	PersonalIdentification string
}

type Contact struct {
	Address string 
	email string
	contact string 
}

type Teacher struct {
	discipline Discipline
	*Person
	*Contact
}

type Tutor struct {
	*Person
	*Contact
}

type Student struct {
	Tutors []Tutor
	*Person
	*Contact
}
