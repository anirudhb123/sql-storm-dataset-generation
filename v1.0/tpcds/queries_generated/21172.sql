
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        AVG(ss_net_paid_inc_tax) AS average_payment,
        SUM(CASE WHEN ss_list_price > 100 THEN ss_quantity ELSE 0 END) AS high_price_sales
    FROM store_sales
    GROUP BY ss_store_sk
),
customer_return_metrics AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS average_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_store_sk
),
with_null_checks AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'N') AS marital_status,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
profitability_analysis AS (
    SELECT 
        s.ss_store_sk,
        ss.total_profit,
        cm.total_returns,
        (ss.total_profit - COALESCE(cm.total_return_amount, 0)) AS net_profit,
        (ss.total_profit / NULLIF(ss.total_sales, 0)) AS profit_per_sale
    FROM sales_summary ss
    LEFT JOIN customer_return_metrics cm ON ss.ss_store_sk = cm.sr_store_sk
)
SELECT 
    s.sm_ship_mode_id,
    SUM(CASE WHEN w.w_warehouse_name IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS shipped_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
    AVG(coalesce(ws.ws_net_profit, 0)) AS avg_web_profit,
    "Gender breakdown" AS gender_distribution,
    STRING_AGG(CONCAT(gender, ': ', COUNT(*)) ORDER BY COUNT(*) DESC) AS gender_summary
FROM profitability_analysis pa
JOIN ship_mode s ON s.sm_ship_mode_sk IN (1, 2, 3)
LEFT JOIN web_sales ws ON ws.ws_ship_mode_sk = s.sm_ship_mode_sk
LEFT JOIN catalog_sales cs ON cs.cs_item_sk = ws.ws_item_sk
LEFT JOIN with_null_checks wnc ON pa.ss_store_sk = wnc.c_customer_sk
JOIN warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
GROUP BY s.sm_ship_mode_id
HAVING SUM(ws.ws_quantity) > 1000 AND COUNT(DISTINCT pa.ss_store_sk) > 5;
