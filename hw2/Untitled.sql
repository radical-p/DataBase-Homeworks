--a
select id, name 
from student
where name like 'M%a'


--b
select title
from course as c, section as s
where c.course_id = s.course_id and dept_name like '%Eng.' and semester = 'Fall' and year = 2009 


--c
select title, name
from course as c, student as s
where (s.id, c.course_id) in (
	SELECT id, takes.course_id FROM takes
	group by id, course_id
	having COUNT(*) >= 3
)


--d
select prereq_id, sum(credits) as sum_credits
from prereq as p, course as c
where c.course_id = p.course_id
group by prereq_id
having sum(credits) > 4
order by sum_credits desc


--e
with time_hours(time_slot_id, hours) as 
(select diffs.id,sum(diffs.diff)
from (select ts.time_slot_id id, ts.end_hr-ts.start_hr diff
from time_slot ts
where ts.end_hr-ts.start_hr > 0)as diffs
group by diffs.id),
rooms(time_slot_id, room_num) as 
(select s.time_slot_id ,s.room_number 
from "section" s
where s.semester='Spring' and s."year"=2008)


select rm.room_num
from time_hours th,rooms rm
where th.time_slot_id=rm.time_slot_id and th.hours>=2

--f
select name, cnt
from instructor, (select id, count(*) as cnt
	from teaches
	group by id) as foo2
where instructor.id = foo2.id and cnt < (select avg(count)
from (select id, count(*)
	from teaches
	group by id) as foo)
	
	
--g
select * 
from section as s
where s.time_slot_id in (
	select t.time_slot_id
	from time_slot as t
	where start_hr between 8 and 12
) and s.year = 2007 and building = 'Taylor'


--h
select student.id, name, tot_cred, sum 
from student,(
select id, sum(credits) as sum
	from course as c, (
		select * 
		from takes
		where grade like 'A%' or grade like 'B%') as t
	where c.course_id = t.course_id
	group by id) as summation
where student.id = summation.id


--5
--a
with dept_total (dept_name, value) as (select dept_name, sum(salary)
from instructor
group by dept_name),
dept_total_avg(value) as (select avg(value)
from dept_total)
select dept_name
from dept_total, dept_total_avg
where dept_total.value >= dept_total_avg.value;

select dept_name
from(
	select dept_name, sum(salary) as avg_dept
	from instructor
	group by dept_name) as dept_total
where avg_dept > (select avg(avg_dept2)
	from(
	select sum(salary) as avg_dept2
	from instructor
	group by dept_name) as dept_total_avg)


--b
SELECT instructor.name,COUNT(*)
FROM teaches,instructor
WHERE teaches.id=instructor.id AND year=2003
GROUP BY instructor.id
HAVING COUNT(*)>(SELECT AVG(InsTeachCount.TeachCount)
FROM (SELECT instructor.id,COUNT(*) AS TeachCount FROM teaches,instructor
WHERE teaches.id=instructor.id AND year=2003
GROUP BY instructor.id) AS InsTeachCount)


with teach_count as
(SELECT instructor.id as id, instructor.name as name ,COUNT(*)
 AS TeachCount
FROM teaches,instructor
WHERE teaches.id=instructor.id AND year=2003
GROUP BY instructor.id),
avg_teach_count as (SELECT AVG(InsTeachCount.TeachCount) as aver
FROM teach_count AS InsTeachCount)


SELECT teach_count.name, teach_count.TeachCount
FROM teach_count, avg_teach_count
WHERE TeachCount > avg_teach_count.aver


---6
--6a
create table uni_data
(stu_id		    varchar(5),
 stu_name 	    varchar(20) not null,
 stu_dept_name  varchar(20),
 year			numeric(4,0),
 semester		varchar(6),
 course_name    varchar(50),
 score			int,
 is_rank		int,
 foreign key (stu_id) references student (ID),
 foreign key (stu_dept_name) references department (dept_name)
);

drop table uni_data

--6b
insert into uni_data
	(stu_id, stu_name, stu_dept_name, year, semester, course_name, score, is_rank)
(select agg.id, name, agg.dept_name, agg.year, agg.semester, agg.title, agg.scores, (
case 
	when agg.scores > 70 then 1
	else 0
end)  
from (
	select s.ID as id, name, c.dept_name as dept_name, year, semester, title, 
	(case
  when grade = 'A+' then 100
  when grade = 'A ' then 95
  when grade = 'A-' then 90
  when grade = 'B+' then 85
  when grade = 'B ' then 80
  when grade = 'B-' then 75
  when grade = 'C+' then 70
  when grade = 'C ' then 65
  when grade = 'C-' then 60
  else 0
 end) as scores
	from student as s, takes as t, course as c
	where s.id = t.id and t.course_id = c.course_id) as agg)

--6c
update uni_data
set score = case
		when score < 75 then score + 10
		else score + 15
end 
where stu_dept_name = 'Physics'


--6d
delete from uni_data as u where u.stu_id in (select u1.stu_id
from uni_data as u1
where stu_name like 'T%' and score < (select avg(score) 
from uni_data as u2
group by stu_dept_name
having u1.stu_dept_name = u2.stu_dept_name))


SELECT * FROM uni_data
