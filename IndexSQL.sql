select * from category;
select * from products;
select * from sales;
select * from stores;
select * from warranty;

select Count(*) from sales;


---	Improving Query Performance	---

--et = 80 ms
--pt = 9 ms
EXPLAIN ANALYZE
select * from sales
where product_id = 'P-44';

--To optimise we created a index on product id column within sales table.
CREATE INDEX sales_p_id on sales(product_id);
--pt = 0.13 ms
--et = 3.45 ms

--pt = 0.094 ms
--et = 80.448 ms
EXPLAIN ANALYZE
select * from sales
where store_id = 'ST-33';


CREATE INDEX sales_s_id on sales(store_id);
--pt = 1.979 ms
--et = 1.49 ms

CREATE INDEX sales_sale_date on sales(sale_date);
