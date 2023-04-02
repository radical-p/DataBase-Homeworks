select * from DEPARTMENT

--3A
CREATE VIEW people AS
(select id, name, 
				CASE
				WHEN dept_name like '%Eng%' THEN 'Engineer'
				ELSE 'Scientist'
				END as dept_type,
					CASE
					WHEN tp = 1 THEN 'INS'
					ELSE 'STU'
					END as person_type
FROM (SELECT id, name, dept_name, 1 as tp
	FROM instructor
	UNION
	SELECT id, name, dept_name, 2 as tp
	FROM student) AS foo)


--3B
SELECT people.id ,name, person_type, 
									CASE
									WHEN person_type = 'INS'
									THEN (SELECT (salary/budget) * 100
										  FROM instructor, department
									      WHERE instructor.dept_name = department.dept_name 
										  AND instructor.id = people.id)
								    ELSE (SELECT part
										  FROM (SELECT department.dept_name, budget/COUNT(*) as part
										  		FROM student
										  		INNER JOIN department
										  		ON student.dept_name = department.dept_name
										  		GROUP BY department.dept_name, budget) AS FOO
										  INNER JOIN student
										  ON student.dept_name = FOO.dept_name
										  WHERE student.id = people.id)
									END
FROM people

--5.a
BEGIN TRANSACTION;

INSERT INTO department
VALUES('medical', 'Pasteur', 700000);

INSERT INTO department
VALUES('dental', 'Pasteur', 800000);

COMMIT TRANSACTION;


COMMIT

--5.b
BEGIN TRANSACTION;

UPDATE department
SET budget = budget + (SELECT budget/10 FROM department WHERE dept_name = 'medical')
WHERE dept_name = 'dental';

UPDATE department
SET budget = budget - (SELECT budget/10 FROM department WHERE dept_name = 'medical')
WHERE dept_name = 'medical';

COMMIT TRANSACTION;


-------------------
select * from film

--4a
ALTER TABLE film ADD CONSTRAINT check_lenght CHECK (length > 50);


--4b
ALTER TABLE payment ADD PAY_TYPE VARCHAR(40) CHECK (PAY_TYPE IN ('credit_card', 'cash', 'online'))

CREATE FUNCTION FUNC(act_id integer)
RETURNS TABLE()
RETURN
(
    SELECT film.title, (SELECT count(*)
                        FROM inventory as i, rental as r 
                        WHERE i.inventory_id = r.inventory_id AND r.film_id = film_actor.film_id)
    FROM film_actor, actor, film
    WHERE film_actor.film_id = film.film_id AND actor.actor_id = film_actor.actor_id AND FUNC.act_id = actor.actor_id
)

---------------------------------------------------------------------------------------------------
--7
CREATE OR REPLACE PROCEDURE R_COST2(IN fst_name VARCHAR(40), IN scnd_name VARCHAR(40)) AS $$
    DECLARE 
    VAL numeric(5, 2);
BEGIN
    
    SELECT replacement_cost INTO VAL
    FROM film
    WHERE film.title = R_COST2.fst_name;
        
    UPDATE film
    SET replacement_cost = replacement_cost - (VAL * 5) / 100
    WHERE title = R_COST2.fst_name;
    
    UPDATE film
    SET replacement_cost = replacement_cost + (VAL * 5) / 100
    WHERE title = R_COST2.scnd_name;
END; 
$$
LANGUAGE plpgsql;

CALL R_COST2('Academy Dinosaur', 'Ace Goldfinger');

SELECT * FROM FILM where title = 'Academy Dinosaur' or title = 'Ace Goldfinger'


------------------------------------------------------------------------------------------
--6
CREATE OR REPLACE FUNCTION RENT_C(IN func_id INT)
RETURNS TABLE(actor_id   SMALLINT,
              film_id    SMALLINT,
              title      VARCHAR(255),
              count_rate BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY 
    SELECT film_actor.actor_id, film_actor.film_id, film.title, (
                                            SELECT COUNT(*) 
                                            FROM RENTAL AS R
                                            INNER JOIN INVENTORY AS I
                                            ON R.inventory_id = I.inventory_id
                                            GROUP BY I.film_id
                                            HAVING I.film_id = film.film_id)
    FROM film_actor
    inner join film 
    on film_actor.film_id = film.film_id and film_actor.actor_id = RENT_C.func_id;
END;
$$

SELECT * FROM RENT_C(1);

------------------------------------------------------------------------------
--8
select * from rental WHERE CUSTOMER_ID = 1

ALTER TABLE CUSTOMER ADD count_check INTEGER 

UPDATE CUSTOMER
SET count_check = 0

CREATE OR REPLACE FUNCTION test()
  RETURNS trigger AS
$$
BEGIN
         UPDATE CUSTOMER
         SET count_check = count_check + 1
         WHERE NEW.customer_id = CUSTOMER.customer_id;
         
         IF (SELECT count_check
             FROM CUSTOMER
             WHERE NEW.customer_id = CUSTOMER.customer_id) = 3 THEN 
             UPDATE RENTAL
             SET return_date = return_date + interval '1' day * 7;
             WHERE NEW.customer_id = RENTAL.customer_id;
         END IF;
         
         IF (SELECT count_check
             FROM CUSTOMER
             WHERE NEW.customer_id = CUSTOMER.customer_id) = 3 THEN
              UPDATE CUSTOMER
              SET count_check = 0
              WHERE NEW.customer_id = CUSTOMER.customer_id;
         END IF;
           
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER deadline 
   AFTER INSERT 
   ON rental
   FOR EACH ROW
   EXECUTE PROCEDURE test(); 
   
INSERT INTO RENTAL 
VALUES(16055, '2005-07-09 10:08:10', 932, 1, '2005-07-16 16:52:25', 1, '2005-07-16 16:52:25');
INSERT INTO RENTAL 
VALUES(16056, '2005-05-24 22:54:33', 1525, 1, '2005-05-28 19:40:33', 1, '2006-02-16 02:30:53');
INSERT INTO RENTAL 
VALUES(16057, '2005-05-24 23:11:53', 3995, 1, '2005-05-29 20:34:53', 2, '2006-02-16 02:30:53');


DELETE FROM RENTAL WHERE rental_id = 16055 or rental_id = 16056

---------------------------------------------------------------------------------------------------
--9
SELECT * FROM FILM

WITH TOTAL_SELL AS
(SELECT I.film_id, COUNT(*) * (
                   SELECT replacement_cost
                   FROM FILM AS F2
                   WHERE F2.FILM_ID = I.FILM_ID) AS sum_amount
FROM RENTAL AS R
RIGHT JOIN INVENTORY AS I
ON R.inventory_id = I.inventory_id
GROUP BY I.film_id)

SELECT FILM.TITLE,
film.rating,
rank () over (order by (sum_amount) desc) as rank_in_all,
rank () over (partition by rating order by (sum_amount) desc) AS rank_in_rating,
sum_amount,
CASE
 WHEN NTILE(4) OVER(ORDER BY sum_amount) = 1 THEN 'YES'
 ELSE 'NO'
END
FROM TOTAL_SELL
INNER JOIN FILM 
ON FILM.FILM_ID = TOTAL_SELL.FILM_ID


-------------------------------------------------------------------------------------------
-----10

select distinct rating, 
date_part('month', payment_date),
sum(amount) over (partition by rating , date_part('month', payment_date)) as this_month,
sum(amount) over (partition by rating order by date_part('month', payment_date) range between 1 following and 1 following) as next_month,
sum(amount) over (partition by rating order by date_part('month', payment_date) range between 1 preceding and 1 preceding) as last_month
from payment, rental, inventory, film
where payment.rental_id = rental.rental_id and rental.inventory_id = inventory.inventory_id and
inventory.film_id = film.film_id
order by date_part('month', payment_date)







					