
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(SUM(s.ss_ext_sales_price), 0) AS total_sales,
        1 AS level
    FROM customer c 
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name),
        sh.total_sales * 1.1, 
        sh.level + 1
    FROM customer c
    JOIN SalesHierarchy sh ON sh.c_customer_sk = c.c_customer_sk 
    WHERE sh.level < 5
),
AggregateSales AS (
    SELECT 
        c.c_birth_year,
        SUM(s.total_sales) AS accumulated_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(s.total_sales) DESC) AS rank
    FROM SalesHierarchy s 
    JOIN customer c ON s.c_customer_sk = c.c_customer_sk
    GROUP BY c.c_birth_year
),
TopSales AS (
    SELECT 
        c.c_birth_year,
        a.accumulated_sales
    FROM AggregateSales a
    JOIN customer c ON a.c_birth_year = c.c_birth_year
    WHERE a.rank <= 3
)
SELECT 
    ta.c_birth_year,
    ta.accumulated_sales,
    CASE 
        WHEN ta.accumulated_sales IS NULL THEN 'No Sales'
        WHEN ta.accumulated_sales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    ca.ca_city,
    ca.ca_state,
    COALESCE(MAX(inventory.inv_quantity_on_hand), 0) AS stock_on_hand
FROM TopSales ta
LEFT JOIN customer_address ca ON ta.c_birth_year = ca.ca_address_sk
LEFT JOIN inventory ON inventory.inv_item_sk = ta.accumulated_sales 
GROUP BY 
    ta.c_birth_year, 
    ta.accumulated_sales, 
    ca.ca_city, 
    ca.ca_state
ORDER BY ta.accumulated_sales DESC;
