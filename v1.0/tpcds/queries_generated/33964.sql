
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        cs_sold_date_sk
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
),
total_sales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.total_quantity) AS combined_quantity,
        SUM(s.total_sales) AS combined_sales
    FROM 
        sales_cte s
    GROUP BY 
        s.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    SUM(ts.combined_sales) AS total_sales_value,
    COUNT(ts.combined_quantity) AS total_transitions,
    d.d_date AS transaction_date,
    CASE 
        WHEN cd.cd_marital_status IS NULL THEN 'UNKNOWN'
        ELSE cd.cd_marital_status 
    END AS marital_status,
    NULLIF(cd.cd_credit_rating, '') AS credit_rating
FROM 
    total_sales ts
JOIN 
    customer_info ci ON ci.c_customer_sk = ts.ws_item_sk
JOIN 
    date_dim d ON d.d_date_sk = ts.ws_item_sk
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name,
    d.d_date,
    cd.cd_marital_status,
    cd.cd_credit_rating
HAVING 
    SUM(ts.combined_sales) > 1000
ORDER BY 
    total_sales_value DESC
LIMIT 100;
