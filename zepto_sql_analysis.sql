CREATE DATABASE zepto_db
USE zepto_db
DROP TABLE IF EXISTS zepto;
CREATE TABLE zepto (
  sku_id SERIAL PRIMARY KEY,
  category VARCHAR(120),
  name VARCHAR(150) NOT NULL,
  mrp NUMERIC(8,2),
  discountPercent NUMERIC(5,2),
  availableQuantity INTEGER,
  discountedSellingPrice NUMERIC(8,2),
  weightInGms INTEGER,
  outOfStock BOOLEAN,
  quantity INTEGER
);

-- data exploration


select * from zepto_v2

-- count of rows
select count(*) from zepto_v2

-- sample data
select * from zepto_v2 limit 10;

-- null values
select * from zepto_v2
where name is null or
Category is null or
mrp is null or
discountpercent is null or
availableQuantity is null or
weightInGms is null or
outOfStock is null or
quantity is null ;
-- ok so there are no null values in the dataset

-- different product categories
select distinct Category
from zepto_V2

-- no of products in stock vs out of stock
select outOfStock,count(*) as Noofproducts from zepto_v2
group by outOfStock 

-- products names multiple times
select name ,count(*) as c from zepto_v2
group by name 
having count(*) > 3
order by c desc;

-- so till now we are done with the data exploration



-- data cleaning 
-- products with price=0
select * from zepto_v2
where mrp=0 or discountedSellingPrice=0;

-- Found top 10 best-value products based on discount percentage
select distinct name,mrp,discountPercent from zepto_v2
order by discountPercent Desc 
limit 10;


-- Identified high-MRP products that are currently out of stock
select Category,name,mrp from zepto_v2
where mrp>300 and outOfStock="true"
order by mrp desc 
limit 10;

-- Estimated potential revenue for each product category
select  Category,sum(discountedSellingPrice*availableQuantity) as totalrevenue from zepto_v2
group by Category
order by totalrevenue  desc;

-- Filtered expensive products (MRP > ₹500) with minimal discount
select distinct name,mrp,discountpercent
from zepto_v2
where mrp>500 and discountPercent<10 
order by mrp desc,discountpercent desc;

-- Rank top 5 categories offering highest average discounts
select Category,round(avg(discountedSellingPrice)) as avgdiscount
 from zepto_v2
group by category
order by avgdiscount desc
limit 5;

-- Grouping products based on weight into Low, Medium, and Bulk categories
select Category , weightInGms as w, case 
when weightInGms<1000 then "low" 
when weightInGms<5000 then "medium"
else "bulk" 
end as weight_Category
from zepto_v2;

-- Measuring total inventory weight per product category

select Category,Sum(weightInGms*availableQuantity) as total_weight
from zepto_v2 
group by category
order by total_weight desc;



-- advanced sql 
-- Retrieving the top 3 products with the highest MRP in each category

SELECT *
FROM (
  SELECT *,
         RANK() OVER (PARTITION BY Category ORDER BY mrp DESC) AS rnk
  FROM zepto_v2
) AS ranked
WHERE rnk <= 3;

-- finding the percentage of products that are out of stock 
SELECT 
  ROUND(SUM(outOfStock ="true") * 100.0 / COUNT(*), 2) AS out_of_stock_percent
FROM zepto_v2;

-- Creating a view summarizing discount and stock status by category
CREATE VIEW category_summary_view AS
SELECT Category,
       COUNT(*) AS total_items,
       ROUND(AVG(discountPercent), 2) AS avg_discount,
       SUM(outOfStock ="true") AS out_of_stock
FROM zepto_v2
GROUP BY Category;
select * from category_summary_view;


-- Finding the top 5 products by quantity in stock per category using a CTE 
WITH RankedStock AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY Category ORDER BY quantity DESC) AS rn
  FROM zepto_v2
)
SELECT * FROM RankedStock
WHERE rn <= 5;


-- using joins queries
CREATE TABLE category_info (
    Category VARCHAR(100) PRIMARY KEY,
    is_frozen BOOLEAN,
    department VARCHAR(100)
);
INSERT INTO category_info (Category, is_frozen, department) VALUES
('Dairy, Bread & Batter', TRUE, 'Cold Storage'),
('Fruits & Vegetables', FALSE, 'Produce'),
('Biscuits', FALSE, 'Pantry'),

('Personal Care', TRUE, 'Frozen Section');
select * from category_info

SELECT zd.name, zd.Category, ci.department
FROM zepto_v2 as zd
JOIN category_info ci ON zd.Category = ci.Category
WHERE zd.outOfStock = "true" AND ci.is_frozen = TRUE;
select distinct Category from zepto_v2;

-- creating a stored procedures


DELIMITER //

CREATE PROCEDURE GetCategorySummary(IN cat_name VARCHAR(100))
BEGIN
  SELECT COUNT(*) AS product_count,
         ROUND(AVG(discountPercent), 2) AS avg_discount
  FROM zepto_v2
  WHERE Category = cat_name;
END //

DELIMITER ;
-- executing the stored procedure
CALL GetCategorySummary('Beverages');
