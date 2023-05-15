
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- 1.what is the total amount each customer spent on Zomato

select USER_ID, sum(price) as totalAmountSpent
from ZomatoProject.dbo.sales s inner join ZomatoProject.dbo.product p on s.product_id =p.product_id
group by user_id;

-- 2.How many days has each customer vistied on zomato

select USER_ID, count(created_date) NoOfVisits
from ZomatoProject.dbo.sales
group by  user_id;

--3. what was the first product purchased by each customer

select * from (select user_id, product_id ,rank() OVER (Partition By user_id order by created_date) as num
from ZomatoProject.dbo.sales) a
where num=1; 

--4. which is the most purchased item on the menu and how many times was it purchased by all customers

select user_id , count(user_id) as cnt, product_id from ZomatoProject.dbo.sales
where product_id= (select top 1 product_id 
from ZomatoProject.dbo.sales
group by product_id 
order by count(product_id) desc)
group by user_id, product_id;

-- 5. which product was most popular for each cutomer

select * from (
select *, Rank() over(partition by user_id order by cnt desc)  rnk from
(select user_id ,product_id, count(product_id) as cnt
from ZomatoProject.dbo.sales 
group by user_id ,product_id)a)b 
where rnk=1

--6. which item was purchased first by the customer after they became a member?

select product_id, user_id, created_date from (select *, rank() over(partition by user_id order by created_date asc) as rnk 
from (select s.product_id, s.user_id, created_date from ZomatoProject.dbo.sales s inner join ZomatoProject.dbo.goldusers_signup g
on s.user_id=g.user_id
where created_date >= gold_signup_date)a)b where rnk=1

--7. which item was purchased just before the customer became a member?

select product_id, user_id, created_date from (select *, rank() over(partition by user_id order by created_date desc) as rnk 
from (select s.product_id, s.user_id, created_date from ZomatoProject.dbo.sales s inner join ZomatoProject.dbo.goldusers_signup g
on s.user_id=g.user_id
where created_date< gold_signup_date)a)b where rnk=1


--8. what is the total orders and amount spent for each member before they became a member

select count(s.product_id) totalOrders, s.user_id, sum(price) totalAmount from ZomatoProject.dbo.sales s inner join ZomatoProject.dbo.goldusers_signup g
on s.user_id=g.user_id inner join ZomatoProject.dbo.product p on s.product_id=p.product_id 
where created_date< gold_signup_date
group by s.user_id
order by s.user_id


/* 9. If buying each product generates points for e.g 5rs=2points and each product generates different points 
for e.g for p1 5rs.=1 point , for p2 10rs=5points and for p3 5rs. = 1points 
Calculte points collected by each customers and for which product most points have been given till now 
*/

select user_id ,sum(pointsCollected) as totalPoints from (
select s.product_id, s.user_id, price,
case when s.product_id=1 then price/5 
	when s.product_id=2 then price/2
	when s.product_id=3 then price/5
	end as pointsCollected
from ZomatoProject.dbo.sales s  inner join ZomatoProject.dbo.product p on s.product_id=p.product_id)a
group by user_id
order by user_id;


select top 1 product_id ,sum(pointsCollected) as totalPoints from (
select s.product_id, s.user_id, price,
case when s.product_id=1 then price/5 
	when s.product_id=2 then price/2
	when s.product_id=3 then price/5
	end as pointsCollected
from ZomatoProject.dbo.sales s  inner join ZomatoProject.dbo.product p on s.product_id=p.product_id)a
group by product_id
order by totalPoints desc;

/* 10. In the first one year of gold purchase (including their joining date) irresective of what the customer has purchased 
they earn 5 zomato points for every 10rs. spent.
calculate who earned more and what was their earnings in their first year */

select top 1 s.user_id, s.product_id, price, price/2 as points
from 
ZomatoProject.dbo.sales s  inner join ZomatoProject.dbo.product p on s.product_id=p.product_id
inner join ZomatoProject.dbo.goldusers_signup g
on s.user_id=g.user_id 
where  12 > DATEDIFF(month,  gold_signup_date, created_date) and DATEDIFF(month, gold_signup_date, created_date)> 0 
order by price desc;


-- 11. Rank all the transactions of customers

select user_id, DENSE_RANK() over(partition by user_id order by created_date) rnk
from ZomatoProject.dbo.sales 



-- 12. Rank all the transactions for each member whenever they are a zomato gold member. And for every non gold member transaction mark as NA

select *, case when rnk=0 then 'NA' else rnk end as rnkk from (
select s.user_id,product_id,created_date , gold_signup_date,
cast((case when gold_signup_date is null then 0 else rank() over( partition by s.user_id order by created_date desc) end) as varchar)
 as rnk
from ZomatoProject.dbo.sales s left join ZomatoProject.dbo.goldusers_signup g
on s.user_id=g.user_id and created_date> gold_signup_date)a
