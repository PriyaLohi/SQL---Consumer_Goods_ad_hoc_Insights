Q1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.

SELECT market 
FROM dim_customer
where region = "APAC" and customer = "Atliq Exclusive"

Q2. What is the percentage of unique product increase in 2021 vs. 2020?

SELECT 
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_product_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_product_2021,
    ROUND(
        (COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) - 
         COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) * 100.0 /
         NULLIF(COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END), 0), 
        2
    ) AS percentage_change
FROM gdb023.fact_sales_monthly;

3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. 
 
SELECT count(distinct product_code) as product_count, segment 
FROM gdb023.dim_product
group by segment
order by product_count desc

4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020?
with product_count as(
        SELECT p.segment,   
		COUNT(DISTINCT CASE WHEN s.fiscal_year = 2020 then s.product_code END) as product_code_2020,
		COUNT(DISTINCT CASE WHEN s.fiscal_year = 2021 then s.product_code END) as product_code_2021
	FROM fact_sales_monthly s
        JOIN dim_product p 
        ON s.product_code= p.product_code
        GROUP BY p.segment
)
SELECT 
      segment,
      product_code_2020,
      product_code_2021,
      ROUND(
			(product_code_2021 - product_code_2020) * 100.0 /NULLIF( product_code_2020, 0), 
            2
		) as difference
FROM product_count
order by difference desc
limit 1000;        

5. Get the products that have the highest and lowest manufacturing costs.

WITH cte AS (
    SELECT 
        p.product, 
        MAX(m.manufacturing_cost) AS highest_manufacturing_cost, 
        MIN(m.manufacturing_cost) AS lowest_manufacturing_cost
    FROM gdb023.fact_manufacturing_cost m
    JOIN dim_product p ON m.product_code = p.product_code
    GROUP BY p.product
    order by  highest_manufacturing_cost, lowest_manufacturing_cost desc
)
SELECT * FROM cte;
6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market.

SELECT i.customer_code, c.customer, ROUND(AVG(pre_invoice_discount_pct),2) as avg_pre_invoice_dct_pct
FROM gdb023.fact_pre_invoice_deductions i
JOIN dim_customer c
ON i.customer_code = c.customer_code
where fiscal_year =2021 and c.market = "India"
group by i.customer_code, c.customer
order by avg_pre_invoice_dct_pct desc
limit 5;

7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions

SELECT 
     YEAR(s.date) as Year,
     MONTH(s.date) as Month,
     round(sum(g.gross_price*s.sold_quantity),2) as gross_sales_amount 
     FROM gdb023.fact_sales_monthly s
     JOIN fact_gross_price g 
     ON s.product_code= g.product_code
     JOIN dim_customer c
     ON c.customer_code = s.customer_code
     WHERE c.customer = "Atliq Exclusive"
     group by Year, month
     order by year, Month
     
8. In which quarter of 2020, got the maximum total_sold_quantity? 
with cte as ( 
		SELECT quarter(date) as qtr, sum(sold_quantity) as total_sold_qty
		FROM gdb023.fact_sales_monthly
		where fiscal_year =2020
        group by qtr
        )
select * from cte        
order by total_sold_qty desc
limit 4;

9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution?
  
   with cte1 as(
		SELECT c.channel,
		sum(g.gross_price*s.sold_quantity) as gross_sales_mln
		FROM fact_sales_monthly s
		JOIN fact_gross_price g
		ON s.product_code = g.product_code
		Join dim_customer c
		ON c.customer_code=s.customer_code
		where s.fiscal_year = 2021
        group by c.channel
        order by gross_sales_mln desc
      ),
cte2 as (     
       Select *, sum(gross_sales_mln) over() as total_gross_sales
       from cte1
       )
select *, 
       ROUND((gross_sales_mln/total_gross_sales)*100,2) as pct_contribution
       from cte2
       order by gross_sales_mln desc
       limit 1;

10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?

with cte1 as (
		select 
				s.product_code, p.product, p.division, 
				sum(sold_quantity) as total_sold_qty
				from fact_sales_monthly s
				JOIN dim_product p
				ON s.product_code=p.product_code
				where fiscal_year= 2021
				group by s.product_code, p.product, p.division
				order by total_sold_qty desc
         ),
         cte2 as (
               select *,
               dense_rank() over(partition by division order by total_sold_qty desc) as drnk
               from cte1
          )
 select * from cte2 where drnk<=3  






















