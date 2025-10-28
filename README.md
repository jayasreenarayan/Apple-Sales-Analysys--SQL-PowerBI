# Apple-Sales-Analysys-SQL-PowerBI [Dataset-1M]

<img width="1310" height="700" alt="image" src="https://github.com/user-attachments/assets/507f2391-d355-46cf-9eca-491d168c2ca4" />


This project demonstrates advanced SQL querying Techniques on dataset of over 1Million roles from Apple sales record. 

## Problem Statement
Apple’s retail operations generate massive volumes of sales and warranty data across global stores. 
The challenge is to analyze this data to uncover trends, identify underperforming products, assess warranty risks, and support strategic decisions using SQL-based analytics.

## Database Overview
The project uses a normalized relational schema in Microsoft SQL Server with the following 5 core tables:

sales_data: Records of product sales including date, store, and quantity.

products: Details like product name, category, and price.

stores: Location and region of Apple retail outlets.

warranty_claims: Claim type, status, and resolution details.

categories: Product classification for analysis.

The data spans over 1 million rows, imported from CSV files using BULK INSERT.

## Solutions & Key Problems Addressed
This project primarily focuses on leveraging SQL to explore data from multiple tables

Complex Joins and Aggregations: Demonstrating the ability to perform complex SQL joins and aggregate data frm multiple tables

Window Functions: Using advanced window functions for running totals, growth analysis, and time-based queries

Data Segmentation: Analyzing data across different time frame to gain insights into product performance

Correlation Analysis: Applying SQL functions to determine relationships between variables, such as product price and warranty claims

## ERD: 
<img width="1319" height="712" alt="image" src="https://github.com/user-attachments/assets/992cf5b2-63d4-4917-819d-63d6165d17d4" />

## Key SQL solutions:

1) For each store, identify the best-selling day based on highest quantity sold
 ```
select * from
(
	select
    store_id,
    to_char(sale_date, 'day') as day_name,
    sum(quantity) as Total_Quantity_sold,
    rank() over(partition by store_id order by sum(quantity) desc) as rank
    from sales
    group by 1,2
) as tb1
where rank = 1

```
2) Determin how many warranty claims were filed for products launched in the last two years
```
select p.product_name, count(w.claim_id), count(s.sale_id) from
warranty as w
right join sales as s on w.sale_id = s.sale_id
join products as p
on p.product_id = s.product_id
where launch_date >= current_date - interval '2years'
group by 1
having count(w.claim_id) > 0;

```
3) Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period
```
with monthly_sales
as
(select store_id,
extract(year from sale_date) as year,
extract(month from sale_date) as month,
sum(p.price * s.quantity) as Total_profit
from sales as s
join products as p
on s.product_id = p.product_id
group by 1, 2, 3
order by 1, 2, 3)

select
store_id, 
year, 
month, 
Total_profit, 
sum(total_profit) over(partition by store_id order by year, month) as Running_total
from monthly_sales;
```
