
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk

    UNION ALL

    SELECT ss_item_sk, SUM(ss_quantity), SUM(ss_net_paid)
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(s.total_sales, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(s.total_sales, 0) < 1000 THEN 'Low Sales'
        ELSE 'High Sales' 
    END AS sales_category
FROM 
    item i
LEFT JOIN 
    sales_cte s ON i.i_item_sk = s.ws_item_sk OR i.i_item_sk = s.ss_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 50;

SELECT DISTINCT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    SUM(sr_return_amt) AS total_returns
FROM 
    customer c
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    c.c_birth_year IS NOT NULL
GROUP BY 
    c.c_customer_id, full_name, gender
HAVING 
    SUM(sr_return_amt) > 0
ORDER BY 
    total_returns DESC;
