
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_day, 
        c.c_birth_month, 
        c.c_birth_year, 
        1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_day, 
        c.c_birth_month, 
        c.c_birth_year, 
        ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
returns_data AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
final_data AS (
    SELECT 
        i.i_item_id,
        sd.total_sales,
        IFNULL(rd.total_returns, 0) AS total_returns,
        (IFNULL(sd.total_sales, 0) - IFNULL(rd.total_returns, 0)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY net_sales DESC) AS rank
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN returns_data rd ON i.i_item_sk = rd.wr_item_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_day,
    ch.c_birth_month,
    ch.c_birth_year,
    fd.i_item_id,
    fd.total_sales,
    fd.total_returns,
    fd.net_sales
FROM customer_hierarchy ch
LEFT JOIN final_data fd ON ch.c_customer_sk = fd.i_item_id
WHERE ch.level <= 3
ORDER BY ch.c_last_name, net_sales DESC
LIMIT 100;
