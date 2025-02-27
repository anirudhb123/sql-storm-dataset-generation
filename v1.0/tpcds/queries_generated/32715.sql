
WITH RECURSIVE sales_trend AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        COALESCE(SUM(ws_quantity), 0) + total_quantity, 
        COALESCE(SUM(ws_net_profit), 0) + total_profit,
        rn + 1
    FROM web_sales ws
    JOIN sales_trend st ON ws_sold_date_sk = st.ws_sold_date_sk + 1 AND ws_item_sk = st.ws_item_sk
    GROUP BY ws_sold_date_sk, ws_item_sk, st.total_quantity, st.total_profit, rn
), 
daily_stats AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(st.total_quantity) AS daily_quantity,
        SUM(st.total_profit) AS daily_profit,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM sales_trend st
    JOIN date_dim d ON d.d_date_sk = st.ws_sold_date_sk
    GROUP BY d.d_date
), 
customer_data AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    ds.sales_date,
    ds.daily_quantity,
    ds.daily_profit,
    cd.gender,
    cd.total_customers,
    cd.married_count,
    AVG(ds.daily_profit) OVER (PARTITION BY cd.gender) AS avg_daily_profit,
    MAX(ds.daily_quantity) OVER () AS max_daily_quantity
FROM daily_stats ds
LEFT JOIN customer_data cd ON ds.unique_customers = cd.total_customers
WHERE ds.daily_profit > (SELECT AVG(daily_profit) FROM daily_stats) 
ORDER BY ds.sales_date DESC
LIMIT 100;
