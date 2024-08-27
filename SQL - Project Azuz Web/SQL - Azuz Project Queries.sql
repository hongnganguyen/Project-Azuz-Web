-----Create Azuz data base 
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
-----1.CUSTOMER BEHAVIOR AND PURCHASE PATTERNS ON AZUZ WEBSITE 
--1.1. Overall:What is the total amount each customer spent on Azuz ? 
SELECT sa.userid
       ,SUM(price) total_spent 
FROM sales  sa
JOIN product pro 
ON sa.product_id = pro.product_id 
GROUP BY sa.userid

--1.2. Frequency: How many days has each customer visited Azuz?
SELECT userid
      ,COUNT(distinct created_date) distinct_day 
FROM sales 
GROUP BY userid 

--1.3. Product Preferences: What was the fist product purchased by each customer ? 
WITH rank_table AS (
SELECT * 
      , RANK() OVER (PARTITION BY userId ORDER BY created_date) rnk 
FROM sales 
) 
SELECT * 
FROM rank_table
WHERE rnk = 1 
--Disscussion: Our analysis indicates that product_ID = 1 is the most frequently purchased item by new customers.
--This compelling data underscores the need for heightened focus and resource allocation to this product category

--1.4. Popular Items: What is the most purchased items the menu and how many times was it purchased by all customer ? 
SELECT userid
      ,COUNT(product_id) AS time_pur 
FROM sales
WHERE product_id = 
      (SELECT Top 1 product_id
      FROM sales
      GROUP BY product_id
      ORDER BY COUNT(product_id) DESC) 
GROUP BY userid
---Discussion: Although the first product attracted initial interest, customer purchasing patterns have shifted towards the second product, indicating a change in preferences.

--1.5. Popular Items by each customer: Which items was the most popular for each customer 
WITH num_table AS (
SELECT userid
      ,product_id
	  ,COUNT(product_id) num_pro
FROM sales 
GROUP BY userid, product_id 
) 
, rank_table AS (
SELECT * 
      ,RANK() OVER (PARTITION BY userid ORDER BY num_pro DESC) rnk  
FROM num_table
) 
SELECT * 
FROM rank_table
WHERE rnk = 1 
 
 -----2. CUSTOMER BEHAVIOR AND PURCHASE PATTENS BEFORE AND AFTER MEMBERSHIP
--2.1. Which item was purchased first by the customer after they became a menber ?
WITH join_table AS (
SELECT sa.* 
      ,gold_signup_date 
FROM sales sa 
JOIN goldusers_signup gol 
ON sa.userid = gol.userid 
WHERE created_date > gold_signup_date 
) 
, rank_table AS (
SELECT *
      ,RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) rnk 
FROM join_table
) 
SELECT * 
FROM rank_table
WHERE rnk = 1 

--2.2. Which item was purchased just before the customer became a menber ? 
WITH join_table AS (
SELECT sa.* 
      ,gold_signup_date 
FROM sales sa 
JOIN goldusers_signup gol 
ON sa.userid = gol.userid 
WHERE created_date <= gold_signup_date 
) 
, rank_table AS (
SELECT *
      ,RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) rnk 
FROM join_table
) 
SELECT * 
FROM rank_table
WHERE rnk = 1 

--2.3.What is the total orders and amount spent for each menber before they became a menber ? 
WITH join_table AS (
SELECT sa.* 
      ,gold_signup_date
	  ,price 
FROM sales sa 
JOIN goldusers_signup gol 
ON sa.userid = gol.userid 
JOIN product pro 
ON sa.product_id = pro.product_id 
WHERE created_date <= gold_signup_date 
) 
SELECT userid
      , COUNT(product_id) total_orders 
	  , SUM(price) total_spent 
FROM join_table
GROUP BY userid
---Discussion:Before and after becoming a member, customer ID=1 consistently purchased product ID=2. This behavior is the opposite of customer ID=3, whose behavior changed after becoming a member

-----3 CUSTOMER LOYALTY PROGAM ANALYSIS 
--3.1. A program for all purchasing customers
--If you buy each product, you will generate points, each product has different purchase points, for p1 it is 5$ = 1 Azuz point, for p2 it is 2$ = 1 Azuz point and p3 is 5$ = 1 Azuz point, 2rs = 1 Azuz point.And the accumulated points will be converted into money to reduce the following bills with 2 Azuz points = 5$. The points each customer accumulates are converted into money and which product has accumulated the most points so far.
---The points each customer accumulates are converted into money  
WITH join_table AS (
SELECT sa.*
      ,price 
FROM sales sa 
JOIN product pro 
ON sa.product_id = pro.product_id 
) 
,amount_table AS (
SELECT userid 
      ,product_id 
	  ,SUM(price) amount 
FROM join_table 
GROUP BY userid,product_id 
) 
, points_table AS (
SELECT *
      ,CASE WHEN product_id = 1 THEN 5 
	        WHEN product_id = 2 THEN 2  
			WHEN product_id = 3 THEN 5 
			ELSE 0 END  points 
FROM amount_table 
) 
, total_point_table AS(
SELECT * 
      , amount/ points total_points 
FROM points_table 
) 
SELECT userid 
      ,SUM(total_points) * 2.5  AS total_money_earned 
FROM total_point_table 
GROUP BY userid 

---- product has accumulated the most points so far 
WITH join_table AS (
SELECT sa.*
      ,price 
FROM sales sa 
JOIN product pro 
ON sa.product_id = pro.product_id 
) 
,amount_table AS (
SELECT userid 
      ,product_id 
	  ,SUM(price) amount 
FROM join_table 
GROUP BY userid,product_id 
) 
, points_table AS (
SELECT *
      ,CASE WHEN product_id = 1 THEN 5 
	        WHEN product_id = 2 THEN 2  
			WHEN product_id = 3 THEN 5 
			ELSE 0 END  points 
FROM amount_table 
) 
, total_point_table AS(
SELECT * 
      , amount/ points total_points 
FROM points_table 
) 
, earned_table AS (
SELECT product_id 
      ,SUM(total_points) AS total_money_earned 
FROM total_point_table 
GROUP BY product_id
) 
, rank_table AS (
SELECT *
      ,RANK() OVER ( ORDER BY total_money_earned DESC) rnk  
FROM earned_table 
) 
SELECT * 
FROM rank_table 
WHERE rnk = 1 
--Discussion: Our analysis has revealed that product ID=2 is a consistent favorite among customers. Aligning with these findings, the loyalty program has been tailored to incentivize purchases of this product, making it the most rewarded item

----3.2. A program for gold customers
--In the first one year after a customer joins the gold program(including their join date) irrespective of what the customer has purchased they earn 5 Azuz points for every 10$ spent who earned more 1 or 3 and what was their points earnings in their first year. 

WITH join_table AS (
SELECT gold.userid, price  
FROM sales sa 
JOIN goldusers_signup gold 
ON sa.userid = gold.userid 
JOIN product pro 
ON sa.product_id = pro.product_id 
WHERE created_date >= gold_signup_date 
AND created_date < DATEADD(year,1,gold_signup_date) 
)
SELECT userid 
      ,price / 2 total_point_earned 
FROM join_table 
---Discussion: The loyalty program highlights customer 1 as a frequent buyer. Nevertheless, the gold membership program demonstrated a different spending pattern.Customer 3, despite having fewer overall points, showed a significant increase in spending within the first year of membership, indicating the effectiveness of the gold tier benefits.
----4.CUSTOMER TRANSACTION ANALYSIS AND MENBERSHIP IMPACT 
--4.1.rank all the transaction of the customer 
SELECT * 
      ,RANK() OVER (PARTITION BY userid ORDER BY created_date) rnk 
FROM sales 

--4.2.rank all the transactions for each menber whenever they are a Azuz gold menber for every non gold menber transaction mark as na 
WITH join_table AS (
SELECT sa.userid, sa.created_date, sa.product_id, gold.gold_signup_date
FROM sales sa 
LEFT JOIN goldusers_signup gold
ON sa.userid = gold.userid 
AND created_date >= gold_signup_date
) 
, rank_table AS (
SELECT *
      ,CAST((CASE WHEN gold_signup_date is null THEN 0  
	        ELSE RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) 
			END ) AS varchar) rnk 
FROM join_table 
)
SELECT *
      ,CASE WHEN rnk = 0 THEN 'NA' 
	   ELSE rnk 
	   END result 
FROM rank_table 
 