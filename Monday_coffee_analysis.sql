use monday_coffee;

# ERD Data exploration and ERD 

Select count(*) as record_count from city
UNION ALL
Select count(*) as record_count from customers
UNION ALL
Select count(*) as record_count from products
UNION ALL
Select count(*) as record_count from sales;

SELECT* FROM city;
select* from products;
select*from customers;
select*from sales;

-- Reports and Data analysis 
# Coffee Consumers count 
# How many people in each city are estimated to consume coffee, given that 25% population does?

 SELECT city_name, ROUND((population*0.25)/1000000,2) as coffee_consumers_in_Millions
 FROM city
 Order by coffee_consumers_in_Millions DESC;
 
 
 # Q2) Total Revenue from coffee sales
 # What is the total revenue generated from coffee sales across all cities in last quarter of 2023?
 
 SELECT 
 SUM(a.toal)as revenue,
 quarter(a.sale_date)as Qtr,
 year(a.sale_date) as Year_of_sale
 FROM sales as a
 Where year(a.sale_date) = 2023 and quarter(a.sale_date) = 4
 Group BY Qtr, Year_of_sale
 ORDER BY revenue;
 
 SELECT 
 c.city_name,
 SUM(a.toal)as revenue,
 quarter(a.sale_date)as Qtr,
 year(a.sale_date) as Year_of_sale
 FROM sales as a
 join customers as b ON a.customer_id = b.customer_id
 join city as c ON b.city_id = c.city_id
 Where year(a.sale_date) = 2023 and quarter(a.sale_date) = 4
 Group BY  c.city_name, Qtr, Year_of_sale
 ORDER BY revenue DESC;
 
 # Q3) Sales Count for each Product 
 # How many units of each coffee products is sold ?
 
 SELECT row_number() Over(order by COUNT(b.sales_id) DESC) as Index_no,
 a.product_name,
 COUNT(b.sales_id) as Units_sold
 from sales as b
 Right join products as a ON a.product_id = b.product_id
 where b.product_id is not null
 GROUP BY a.product_name
 ORDER BY Units_sold DESC;
 
 # Q4) Average Sales amount for each city 
 
 SELECT DENSE_RANK() OVER(Order by ROUND(avg(b.toal),2) DESC)as Ranking,
 a.city_name, ROUND(avg(b.toal),2) as Average_sales
 FROM city a 
 join customers c ON a.city_id = c.city_id
 join sales b on b.customer_id= c.customer_id
 GROUP BY a.city_name
 ORDER BY Average_sales DESC;
 
 -- Average Sales Amount per customer in each city ? 
 
 SELECT c.city_name, 
 SUM(s.toal) as total_sale,
 COUNT(distinct cu.customer_id) as Number_of_customers,
 ROUND(SUM(s.toal)/COUNT(Distinct cu.customer_id),2) as Average_Sales_per_customer
 FROM sales as s
 join customers as cu ON s.customer_id=cu.customer_id
 join city as c ON c.city_id=cu.city_id
 Group by c.city_name
 ORDER BY total_sale DESC, Average_Sales_per_customer DESC;
 
 
 # Q5) 
 # City Population and coffee consumers
 # Provide a list of cities along with there populations and estimated coffee consumers.
 # return city_name, total current customers, estimated coffee consumers(25%) 
 
 -- select ci.city_name,
--  ROUND((ci.population*0.25)/1000000,2) as Estimated_coffee_consumers_in_Millions,
--  COUNT(DISTINCT c.customer_id) as Current_customer_count
--  FROM city as ci
--  join customers as c
--  ON ci.city_id = c.city_id
--  GROUP BY ci.city_name
--  ORDER BY ci.city_name;

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;


# Q6) 
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

Select *
FROM
(
select c.city_name,
p.product_name,
COUNT(sales_id) as Order_count,
dense_rank() OVER(PARTITION BY c.city_name Order BY COUNT(sales_id) DESC) as Rank_by_volume
FROM sales as s
join products as p
ON p.product_id=s.product_id
join customers as cu
ON cu.customer_id = s.customer_id
join city as c
ON cu.city_id=c.city_id
GROUP BY c.city_name, p.product_name
) as RNK
Where Rank_by_volume <=3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
ci.city_name,
Count(distinct cu.customer_id) as Customer_count
FROM city as ci
join customers as cu
ON ci.city_id=cu.city_id
join sales as s
ON s.customer_id=cu.customer_id
Where s.product_id in(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY ci.city_name;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
With avg_sale_cust as
(
 SELECT c.city_name, 
 SUM(s.toal) as total_sale,
 COUNT(distinct cu.customer_id) as Number_of_customers,
 ROUND(SUM(s.toal)/COUNT(Distinct cu.customer_id),2) as Average_Sales_per_customer
 FROM sales as s
 join customers as cu ON s.customer_id=cu.customer_id
 join city as c ON c.city_id=cu.city_id
 Group by c.city_name
 ),
 
 rent as 
 (
 SELECT city_name,
 estimated_rent
 FROM city
 )
 
 SELECT r.city_name,
 a.Number_of_customers,
 r.estimated_rent,
 a.Average_Sales_per_customer,
 ROUND(r.estimated_rent/a.Number_of_customers,2) as Average_rent_per_customer
 FROM rent as r
 join avg_sale_cust as a
 ON r.city_name=a.city_name
 ORDER BY Average_rent_per_customer DESC;
 
 -- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city


SELECT * from sales;

with monthly_sales as
(
	SELECT c.city_name,
	Year(s.sale_date) as sale_Year,
	MONTH(s.sale_date)as sale_Month,
	SUM(s.toal) as current_month_sale,
	Lag(SUM(s.toal)) over(partition by c.city_name order by Year(s.sale_date), MONTH(s.sale_date)) as Last_month_sale
	FROM sales as s
	join customers as cu
	ON cu.customer_id=s.customer_id
	Join city as c
	ON c.city_id=cu.city_id
	GROUP BY c.city_name, Year(s.sale_date), MONTH(s.sale_date)
),
growth as
(
Select city_name, 
sale_Year, 
sale_Month, 
current_month_sale,
Last_month_sale,
ROUND((current_month_sale - Last_month_sale)*100/Last_month_sale,2) as sale_growth_per
FROM monthly_sales
where Last_month_sale is not null
)

SELECT 
city_name, 
ROUND(avg(sale_growth_per),2) as average_growth_rate,
SUM(case when sale_growth_per > 0 then 1 else 0 end) as Positive_months,
COUNT(*) as total_months,
ROUND(
	SUM(CASE when sale_growth_per >0 then 1 else 0 end)*100/count(*),2
) as growth_rate_percent
FROM growth
GROUP BY city_name
ORDER BY growth_rate_percent DESC, average_growth_rate DESC;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


With avg_sale_cust as
(
 SELECT c.city_name,
 SUM(s.toal) as total_sale,
 COUNT(distinct cu.customer_id) as Number_of_customers,
 ROUND(SUM(s.toal)/COUNT(Distinct cu.customer_id),2) as Average_Sales_per_customer
 FROM sales as s
 join customers as cu ON s.customer_id=cu.customer_id
 join city as c ON c.city_id=cu.city_id
 Group by c.city_name
 ),
 
 rent as 
 (
 SELECT city_name,
 ROUND((population*0.25)/1000000,2) as est_cust_population,
 estimated_rent
 FROM city
 )
 
 SELECT r.city_name,
 a.Number_of_customers,
 a.total_sale,
 r.estimated_rent,
 r.est_cust_population,
 a.Average_Sales_per_customer,
 ROUND(r.estimated_rent/a.Number_of_customers,2) as Average_rent_per_customer
 FROM rent as r
 join avg_sale_cust as a
 ON r.city_name=a.city_name
 ORDER BY a.total_sale DESC, Average_rent_per_customer;
 
 # MY RECOMMENDATIONS 
 
 # city 1 :- PUNE 
 -- 1. It has Highest Revenue
 -- 2. IT has highest positive growth_rate_percent - sales are greater than previous months for most num of months.
 -- 3.  It has a Average rent per customer under 300 with highest avg_sales per customer.alter
 
 # city 2 :- Jaipur
 -- 1. It has very less Average_rent_per_customer. 
 -- 2. It currently has highest number of customers.
 -- 3. it has a very good amount of revenue and average_sale_per_customer with less rent than other cities.alter
 
 # city 3 :- Delhi 
 -- 1. It has highest estimated customer population. 
 -- 2. our good portion of current customers are from Delhi. 
 -- 3. It has average rent per customer below 500. 
 
 







 