
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_id,
        s_store_name,
        s_sales_sk,
        ss_ext_sales_price,
        1 AS level
    FROM store_sales
    JOIN store ON store.s_store_sk = store_sales.ss_store_sk
    WHERE ss_sold_date_sk >= 20230101
    UNION ALL
    SELECT
        sh.s_store_sk,
        sh.s_store_id,
        sh.s_store_name,
        ss.s_sales_sk,
        ss.ss_ext_sales_price,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN store_sales ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE sh.level < 5
),
customer_returns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
item_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
sales_data AS (
    SELECT
        s.s_store_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.return_count, 0) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN store s ON ws.ws_store_sk = s.s_store_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY s.s_store_name, cd.cd_gender
)
SELECT 
    sd.s_store_name,
    sd.gender,
    sd.total_sales,
    sd.total_return_amt,
    sd.return_count,
    (sd.total_sales - sd.total_return_amt) AS net_sales,
    vh.total_net_profit,
    CASE 
        WHEN (sd.total_sales - sd.total_return_amt) > 10000 THEN 'High Performer'
        WHEN (sd.total_sales - sd.total_return_amt) BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM sales_data sd
JOIN item_sales vh ON sd.total_sales > vh.total_net_profit
WHERE sd.return_count < 10
ORDER BY sd.total_sales DESC, sd.gender
LIMIT 100;
