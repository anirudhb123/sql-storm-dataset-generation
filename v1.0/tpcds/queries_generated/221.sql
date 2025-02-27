
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS recent_sales_rank
    FROM web_sales ws
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 1000
),
store_summary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM store_sales ss
    GROUP BY ss.s_store_sk
),
item_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        AVG(sd.ws_ext_sales_price) AS avg_sales_price,
        SUM(sd.ws_quantity) AS total_quantity_sold
    FROM sales_data sd
    INNER JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE sd.recent_sales_rank <= 5
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ip.i_item_id,
    ip.avg_sales_price,
    ss.total_profit,
    ss.total_sales_count
FROM customer_info ci
JOIN item_performance ip ON ci.cd_purchase_estimate >= (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
JOIN store_summary ss ON ss.total_profit > 5000
WHERE ci.cd_gender = 'F'
ORDER BY ci.cd_purchase_estimate DESC, ip.total_quantity_sold DESC
LIMIT 10;
