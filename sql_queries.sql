 -- Q1
 
SELECT DISTINCT(market) 
FROM dim_customer
WHERE region = 'APAC' AND customer = 'Atliq Exclusive' ;

-- Q2 

WITH FY2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_product_2020 
    FROM fact_sales_monthly 
    WHERE fiscal_year = 2020),
    
FY2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_product_2021
    FROM fact_sales_monthly 
    WHERE fiscal_year = 2021)

SELECT unique_product_2020,unique_product_2021,
((unique_product_2021 - unique_product_2020) /unique_product_2020) * 100 AS percent_change
FROM FY2020, FY2021;

-- Q3
 
SELECT segment ,COUNT(product) AS product_count
FROM dim_product 
GROUP BY segment 
ORDER BY product_count DESC ;

-- Q4

WITH FY2020 AS (
    SELECT segment, COUNT(DISTINCT dim_product.product_code) AS product_count_2020
    FROM dim_product
    INNER JOIN fact_sales_monthly ON fact_sales_monthly.product_code = dim_product.product_code
    WHERE fiscal_year = 2020
    GROUP BY segment
),
FY2021 AS (
    SELECT segment, COUNT(DISTINCT dim_product.product_code) AS product_count_2021
    FROM dim_product
    INNER JOIN fact_sales_monthly ON fact_sales_monthly.product_code = dim_product.product_code
    WHERE fiscal_year = 2021
    GROUP BY segment
)
SELECT FY2020.segment, product_count_2020, product_count_2021 ,(product_count_2021 - product_count_2020) AS diffrence
FROM FY2020
INNER JOIN FY2021 ON FY2020.segment = FY2021.segment
ORDER BY diffrence DESC;

-- Q5 

SELECT dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
FROM dim_product
INNER JOIN fact_manufacturing_cost 
ON dim_product.product_code = fact_manufacturing_cost.product_code
WHERE 
    fact_manufacturing_cost.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) or
    fact_manufacturing_cost.manufacturing_cost = (SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- Q6

SELECT dim_customer.customer_code , dim_customer.customer ,ROUND(AVG(pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM dim_customer 
INNER JOIN fact_pre_invoice_deductions 
ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE dim_customer.market = "India" AND fact_pre_invoice_deductions.fiscal_year = 2021
GROUP BY customer,dim_customer.customer_code
ORDER BY average_discount_percentage DESC 
LIMIT 5;

-- Q7 

SELECT 
    MONTH(fact_sales_monthly.date) AS months,
    YEAR(fact_sales_monthly.date) AS years,
    ROUND(SUM(sold_quantity * gross_price) / 1000000, 2) AS Gross_sales_Amount_in_Millions
FROM 
    fact_sales_monthly
INNER JOIN 
    fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
INNER JOIN  
    dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
WHERE 
    dim_customer.customer = "Atliq Exclusive"
AND 
	fact_sales_monthly.fiscal_year = fact_gross_price.fiscal_year
GROUP BY 
    months, years
ORDER BY months;

-- Q8

WITH quarter AS (
    SELECT sold_quantity,
        CASE
            WHEN MONTH(date) BETWEEN 09 AND 11 THEN "Q1"
            WHEN MONTH(date) IN (12, 01, 02) THEN "Q2"
            WHEN MONTH(date) BETWEEN 03 AND 05 THEN "Q3"
            WHEN MONTH(date) BETWEEN 06 AND 08 THEN "Q4"
        END as Quarter
    FROM fact_sales_monthly
        WHERE fiscal_year = 2020)

SELECT Quarter, SUM(sold_quantity) AS total_sold_quantity FROM quarter
    GROUP BY Quarter
    ORDER BY total_sold_quantity DESC;
    
-- Q9 

SELECT
    dim_customer.channel AS Channels,
    ROUND(SUM(sold_quantity * gross_price) / 1000000, 2) AS gross_sales_mln,
    ROUND((SUM(sold_quantity * gross_price) / SUM(SUM(sold_quantity * gross_price)) OVER()) * 100, 2) AS percentage
FROM
    fact_sales_monthly
INNER JOIN
    dim_customer ON dim_customer.customer_code = fact_sales_monthly.customer_code 
INNER JOIN
    fact_gross_price ON fact_gross_price.product_code = fact_sales_monthly.product_code 
WHERE
    fact_gross_price.fiscal_year = 2021
    AND fact_gross_price.fiscal_year = fact_sales_monthly.fiscal_year
GROUP BY
    Channels
ORDER BY
    percentage DESC;
    
-- Q10 

WITH product AS (
	SELECT division , fact_sales_monthly.product_code , product, SUM(sold_quantity) AS total_sold_qty 
    FROM fact_sales_monthly 
    INNER JOIN dim_product 
    ON fact_sales_monthly.product_code = dim_product.product_code 
    WHERE fiscal_year = 2021
    GROUP BY fact_sales_monthly.product_code , division , product ),
    
    rank_table AS (
    SELECT *, RANK () OVER (PARTITION BY division ORDER BY total_sold_qty DESC) AS Rank_order FROM product)
    
    SELECT * from rank_table
    WHERE rank_order <=3;

