
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws.ws_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS sales_rank,
        ws.net_profit,
        ws.net_paid_inc_tax,
        COALESCE(ws.quantity, 0) AS quantity_sold,
        CASE 
            WHEN ws.net_profit IS NULL THEN 'UNKNOWN'
            ELSE CASE 
                WHEN ws.net_profit > 1000 THEN 'HIGH'
                WHEN ws.net_profit BETWEEN 500 AND 1000 THEN 'MEDIUM'
                ELSE 'LOW'
            END 
        END AS profit_category
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq IN (3, 4) 
    )
),
customer_label AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN h.hd_income_band_sk IS NULL THEN 'UNDEFINED'
            ELSE ib.ib_income_band_sk
        END AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cl.c_customer_sk,
    cl.cd_gender,
    cl.cd_marital_status,
    SUM(rs.net_profit) AS total_net_profit,
    SUM(rs.net_paid_inc_tax) AS total_paid,
    COUNT(DISTINCT rs.item_sk) AS unique_items,
    AVG(CASE WHEN rs.sales_rank <= 5 THEN rs.net_profit ELSE NULL END) AS avg_top_sales,
    COUNT(CASE WHEN rs.quantity_sold > 0 THEN 1 END) AS sales_count,
    STRING_AGG(rs.profit_category, ', ') AS profit_categories
FROM customer_label cl
LEFT JOIN ranked_sales rs ON cl.c_customer_sk = rs.bill_customer_sk
GROUP BY cl.c_customer_sk, cl.cd_gender, cl.cd_marital_status
HAVING SUM(rs.net_profit) > 0 OR cl.cd_gender IS NULL
ORDER BY total_net_profit DESC, cl.cd_gender, cl.cd_marital_status;
