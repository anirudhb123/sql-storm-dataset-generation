
WITH RECURSIVE sales_cte AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        1 AS level
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        level + 1
    FROM
        catalog_sales cs
    JOIN sales_cte s ON cs_order_number = s.ws_order_number
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_ext_sales_price) AS total_sales,
    AVG(s.ws_ext_discount_amt) AS average_discount,
    COUNT(DISTINCT s.ws_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ws_ext_sales_price) DESC) AS sales_rank
FROM
    customer c
LEFT JOIN web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS qty,
        SUM(ws_ext_sales_price) AS sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_dow = 1)
    GROUP BY 
        ws_bill_customer_sk
) aggregated_sales ON c.c_customer_sk = aggregated_sales.ws_bill_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    cd.cd_gender = 'F'
    AND (aggregated_sales.qty IS NULL OR aggregated_sales.qty > 10)
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_customer_sk  -- Added to match the window function partition
HAVING 
    SUM(s.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
