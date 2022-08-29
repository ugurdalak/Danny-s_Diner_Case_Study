--Case Study #1 - Danny's Diner
/*CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');*/
--__________________________________________________________
  
--Case Study Questions
--Each of the following case study questions can be answered using a single SQL statement:
--checking each table
select * from members m2; --customer_id,join_date
select * from sales s; --customer_id,order_date,product_id
select * from menu m ; --product_id,product_name,price

--What is the total amount each customer spent at the restaurant?
select
	s.customer_id ,
	sum(m.price)
from
	sales s
join menu m 
on
	s.product_id = m.product_id
group by
	s.customer_id
order by
	1;

--How many days has each customer visited the restaurant?


select
	customer_id,
	count(distinct order_date) as number_of_visits
from
	sales s
group by
	customer_id
order by
	1;

--What was the first item from the menu purchased by each customer? 
with 
	fi 
	as
	(
select
		s.customer_id ,
		s.product_id ,
		m.product_name ,
		s.order_date,
		dense_rank () over (partition by customer_id
order by
	order_date) as rn
from
		sales s
join menu m on
		s.product_id = m.product_id) 
select
	customer_id,
	product_name,
	order_date,
	dense_rank () over (partition by customer_id
order by
	order_date) as rn
from
	fi
where
	rn = 1
group by
	order_date,
	customer_id,
	product_name

    ;
	
--What is the most purchased item on the menu and how many times was it purchased by all customers?
 select
	s.product_id ,
	m.product_name,
	count(order_date)
from
	sales s
join menu m on
	s.product_id = m.product_id
group by
	s.product_id,
	m.product_name
order by
	count(order_date) desc
limit 1;
--Which item was the most popular for each customer? 
WITH
	popular_item
AS
	(
		select
			s.customer_id,
			m.product_name,
			count(m.product_name) order_count,
			dense_rank() over (partition by s.customer_id order by count(m.product_name) desc) rank
		from sales s
		left join menu m on s.product_id = m.product_id
		group by s.customer_id, m.product_name
	)
select 
	customer_id,
	product_name,
	order_count
from popular_item
where rank = 1;

--Which item was purchased first by the customer after they became a member?

with 
fpi
as 
(
select
	s.customer_id,
	m.product_name,
	order_date,
	join_date,
	dense_rank() over (partition by s.customer_id
order by
	s.order_date) rnk
from
	sales s
join menu m on
	s.product_id = m.product_id
join members m2 on
	s.customer_id = m2.customer_id
where
	s.order_date> m2.join_date 
)
select
	customer_id,
	product_name,
	join_date as joincheck,
	order_date as ordercheck
from
	fpi
where
	rnk = 1;

--Which item was purchased just before the customer became a member?
with fi
as (
select
	s.customer_id,
	s.order_date,
	m.product_name,
	m2.join_date,
	dense_rank() over (partition by s.customer_id
order by
	s.order_date desc) rn
from
	sales s
join menu m on
	s.product_id = m.product_id
join members m2 on
	s.customer_id = m2.customer_id
where
	s.order_date < m2.join_date 
)
select
	customer_id,
	product_name,
	order_date as ordercheck,
	join_date as joincheck,
	(
	select
		case
			when order_date < join_date then 'true'
			else 'false'
		end)
from
	fi
where
	rn = 1;
--What is the total items and amount spent for each member before they became a member?
select 
   s.customer_id,
   count(distinct m.product_name) cofitems,
   sum(m.price) amount
   from sales s
   inner join menu m on s.product_id = m.product_id 
   inner join members m2 on s.customer_id = m2.customer_id 
   where s.order_date < m2.join_date 
   group by s.customer_id 
   order by s.customer_id asc ;
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
	s.customer_id,
	sum(tb.points) points
from
	sales s
inner join (
	select
		*,
		case
			when product_name = 'sushi' then price * 20
			else price * 10
		end points
	from
		menu) tb on
	s.product_id = tb.product_id
group by
	s.customer_id
order by
	s.customer_id ;
--In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?

with cmpg
as( 
select
	s.customer_id,
	m.product_name,
	s.product_id,
	sum(m.price) as price,
	m2.join_date,
	s.order_date,
	s.order_date::date - m2.join_date::date,
	(
    select
	case
		when (s.order_date::date - m2.join_date::date)::int between 0 and 6 then 'firstweek'
		else 'notfirstweek'
	end cfw),
	(select case when order_date <= '2021-01-31' then 'okay' else 'not okay' end eof)
from
	sales s
join menu m on
	s.product_id = m.product_id
join members m2 on
	s.customer_id = m2.customer_id
	group by s.customer_id, s.product_id,m.product_name,m2.join_date,s.order_date
	)
select
	customer_id, 
	sum(case 
		when cfw = 'firstweek' then price * 20 
		when cfw = 'notfirstweek' then (case when product_name='sushi' then price*20 else price*10 end)
		end) as totalpoints
from cmpg
where eof='okay'
group by customer_id;

--BONUS QUESTIONS--
--Join All The Things--

with jointable
as
(
select
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	m2.join_date,
	(case when join_date is not null and order_date>= join_date then 'Y' else 'N' end) as member
from
	sales s
left join menu m on
	s.product_id = m.product_id
left join members m2 on
	s.customer_id = m2.customer_id)
select
	customer_id,
	order_date,
	product_name,
	price,
	jointable.member 
from
	jointable
	order by customer_id , member asc ;
	
--Rank All The Things--
with jointable
as
(
select
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	m2.join_date,
	(case
		when join_date is not null
		and order_date >= join_date then 'Y'
		else 'N'
	end) as member
from
	sales s
left join menu m on
	s.product_id = m.product_id
left join members m2 on
	s.customer_id = m2.customer_id)
select
	customer_id,
	order_date,
	product_name,
	price,
	member,
	case
		when member = 'N'
		or member = 'Y'
		and order_date<join_date then null
		when member = 'Y' then
dense_rank() over (partition by customer_id,
		member
	order by
		order_date)
	end as rank
from
	jointable;
	



 