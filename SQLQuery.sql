use apple_db
--1.Find the number of stores in each country
Select country, count(*) from stores group by country order by 2 desc

--2.Calculate the total number of units sold by each store
select st.store_name, s.store_id , sum(s.quantity) as total_unites_sold from stores as st join sales as s 
on st.store_id = s.store_id 
group by st.store_name, s.store_id
order by 3 desc

--3.Identify how many sales occurred in December 2023
select count(sale_id) as num_sales from sales where sale_date >= '2023-12-01' and sale_date< '2024-01-01'


--4.Determine how many stores have never had a warranty claim filed
SELECT COUNT(*) FROM stores
WHERE store_id NOT IN (SELECT DISTINCT store_id FROM sales as s RIGHT JOIN warranty as w
						ON s.sale_id = w.sale_id )

--5.Calculate the percentage of warranty claims marked as "Pending"
Select Round(count(claim_id) / cast((select count(*) from warranty) as numeric) *100,2)
from warranty where repair_status = 'Pending';

--6.Identify which store had the highest total units sold in the last year
SELECT top(1)
	s.store_id,
	st.store_name,
	SUM(s.quantity)
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
WHERE sale_date >= '2023-01-01' and sale_date <'2024-01-01'
GROUP BY s.store_id,st.store_name
ORDER BY 3 DESC 

--7. Count the number of unique products sold in the last year
select
count(distinct product_id)
from sales
where sale_date >= (select current_date - interval '1 year');

--8.Find the average price of products in each category.

select
p.category_id,
c.category_name,
ROUND(Avg(p.price)::numeric, 2) as Avg_price
from products as p
join category as c
on p.category_id = c.category_id
group by 1, 2 
order by 3 desc;

--9.How many warranty claims were filed in 2024?

SELECT distinct EXTRACT(YEAR FROM claim_date) AS year_part FROM warranty;
--To see distict year data

select
count(*) 
from warranty
where extract(year from claim_date) = 2024;

--10.For each store, identify the best-selling day based on highest quantity sold.

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

--11.Identify the least selling product in each country for each year based on total units sold.

with product_rank
as
(
select 
st.country,
p.product_name,
sum(s.quantity),
rank() over(partition by st.country order by sum(s.quantity)) as leaft_sold_product
from sales as s
join stores as st
on s.store_id = st.store_id
join products as p
on s.product_id = p.product_id
group by 1, 2
)
select * from product_rank where leaft_sold_product = 1;

select distinct country from stores; --To verify number of countries by using DISTINCT Function

--12.Calculate how many warranty claims were filed within 180 days of a product sale.

select 
count(*)
from warranty as w
left join sales as s
on w.sale_id = s.sale_id
where w.claim_date - s.sale_date > 0 and w.claim_date - s.sale_date <= 180;

--13.Determin how many warranty claims were filed for products launched in the last two years

select
p.product_name,
count(w.claim_id),
count(s.sale_id)
from
warranty as w
right join sales as s
on w.sale_id = s.sale_id
join products as p
on p.product_id = s.product_id
where launch_date >= current_date - interval '2years'
group by 1
having count(w.claim_id) > 0;

--14.List the months in the last three years where sates exceeded units in the USA.

select
to_char(sale_date, 'MM-YYYY') as Months,
sum(s.quantity) as no_of_Units_sold
from sales as s
join stores as st
on s.store_id = st.store_id
where country = 'United States' and s.sale_date >= current_date - interval '3years'
group by 1
having sum(s.quantity) > 5000

--15.Identify the product category with the most warranty claims filed in the last two years.

select 
c.category_name,
count(w.claim_id) as total_claims
from warranty as w
LEFT JOIN sales as s
ON w.sale_id = s.sale_id
JOIN products as p
ON p.product_id = s.product_id
JOIN category as c
ON c.category_id = p.category_id
where w.claim_date >= CURRENT_DATE - INTERVAL '2years'
group by 1
order by 2 desc;

--16.etermine the percentage chance of receiving warranty claims after each purchase for each country.

select
country,
total_units,
total_claim,
(total_claim::numeric/total_units::numeric) *100 as percentage_of_risk
from
(select
st.country,
sum(s.quantity) as total_units,
count(w.claim_id) as total_claim
from sales as s
join stores as st
on st.store_id = s.store_id
left join warranty as w
on w.sale_id = s.sale_id
group by 1
) tr
order by 4 desc;

--17.Analyze the year-by-year growth ratio for each store.

with yearly_sales
as
(select
S.store_id,
st.store_name,
extract(year from sale_date) as Year_of_sale,
sum(p.price * s.quantity) as total_sale
from sales as s
join products as p
on s.product_id = p.product_id
join stores as st
on st.store_id = s.store_id
group by 1, 2, 3
order by 1, 2, 3
),

growth_ratio
as
(select
store_name,
year_of_sale,
lag(total_sale, 1) over(partition by store_name order by year_of_sale) as last_year_sale,
total_sale as current_year_sale
from yearly_sales
)

select
store_name,
year_of_sale,
last_year_sale,
current_year_sale,
round((current_year_sale - last_year_sale)::numeric/last_year_sale::numeric * 100,2) as growth_ratio_YOY
from growth_ratio
where last_year_sale is not null;

--18.Calculate the correlation between product price and warranty claims for products sold in the tast five years, segmented by price range.

select 
case
when p.price < 500  then 'lower cost'
when p.price between 500 and 1000 then 'moderate cost'
else 'High cost'
end as price_segment,
count(w.claim_id) as total_claim
from warranty as w
left join sales as s
on s.sale_id = w.sale_id
join products as p
on p.product_id = s.product_id
where claim_date >= current_date - interval '5years'
group by 1
order by 2 desc;

--19.Identify the store with the highest percentage of "Completed" claims relative to total claims filed

with completed
as
(select
s.store_id,
count(w.claim_id) as completed
from sales as s
right join warranty as w
on s.sale_id = w.sale_id
where w.repair_status = 'Completed'
group by 1), 

total_repaired 
as
(select
s.store_id,
count(w.claim_id) as total_repaired
from sales as s
right join warranty as w
on s.sale_id = w.sale_id
group by 1)

select 
tr.store_id,
tr.total_repaired,
c.completed,
ROUND(c.completed::numeric/tr.total_repaired::numeric * 100, 2) as percentage_of_completed
from completed as c
join total_repaired as tr
on c.store_id = tr.store_id
order by 4 desc

--20.Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

with monthly_sales
as
(select
store_id,
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