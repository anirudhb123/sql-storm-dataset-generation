
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS store_sales_count,
        SUM(s.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cd.cd_marital_status
),
top_items AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_quantity > 0)
    GROUP BY
        ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.d_year,
    ci.cd_marital_status,
    ti.ws_item_sk,
    ti.total_sales_price,
    ss.total_quantity,
    COALESCE(ss.total_sales_price, 0) AS web_sales_total
FROM 
    customer_info ci
JOIN 
    top_items ti ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk LIMIT 1)
LEFT JOIN 
    sales_summary ss ON ti.ws_item_sk = ss.ws_item_sk AND ss.rn = 1
WHERE 
    ci.store_sales_count > 0
ORDER BY 
    ti.total_sales_price DESC, ci.c_last_name, ci.c_first_name;
