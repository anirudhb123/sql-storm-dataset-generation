
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) as ranking
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) - 30 AND (
            SELECT MAX(d_date_sk)
            FROM date_dim 
            WHERE d_year = 2023
        )
), 
aggregate_sales AS (
    SELECT 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_item_sk) AS item_count
    FROM 
        sales_cte
    GROUP BY 
        ws_order_number
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ag.total_sales,
        ag.item_count
    FROM 
        customer c
    JOIN (
        SELECT 
            s.ws_bill_customer_sk, 
            SUM(s.total_sales) AS total_sales,
            SUM(s.item_count) AS total_items
        FROM 
            aggregate_sales s
        GROUP BY 
            s.ws_bill_customer_sk
        HAVING 
            SUM(s.total_sales) > 1000
    ) ag ON c.c_customer_sk = ag.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    COALESCE(cs.total_sales, 0) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) as rank,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        WHEN cs.total_sales > 5000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    customer_sales cs
LEFT JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC
FETCH FIRST 100 ROWS ONLY;
