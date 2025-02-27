
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 0
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_ranges ir ON ib.ib_income_band_sk = ir.ib_income_band_sk + 1
), 
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT *
    FROM customer_sales
    WHERE rank <= 10
),
return_analysis AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount,
        (SUM(sr.sr_return_amt_inc_tax) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS return_rate
    FROM store_returns sr
    JOIN store_sales ws ON sr.sr_item_sk = ws.ss_item_sk
    GROUP BY sr.sr_item_sk
)

SELECT 
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ir.ib_lower_bound,
    ir.ib_upper_bound,
    ts.total_orders,
    ts.total_profit,
    ra.total_returns,
    ra.total_returned_amount,
    ra.return_rate
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN top_customers ts ON c.c_customer_sk = ts.c_customer_sk
LEFT JOIN income_ranges ir ON cd.cd_purchase_estimate BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
LEFT JOIN return_analysis ra ON c.c_customer_sk = ra.sr_customer_sk
ORDER BY ts.total_profit DESC, c_first_name, c_last_name;
