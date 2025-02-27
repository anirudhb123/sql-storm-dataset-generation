
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ISNULL(hd.hd_buy_potential, 'Unknown') AS demographic_label
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.demographic_label
    FROM customer_info ci
    WHERE ci.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
return_analysis AS (
    SELECT 
        STORES.s_store_sk,
        SUM(sr_return_amt) AS total_refunds
    FROM store_returns sr
    JOIN store STORES ON sr.sr_store_sk = STORES.s_store_sk
    GROUP BY STORES.s_store_sk
),
item_returns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ws.ws_item_sk,
    ws.total_sales,
    MAX(hv.cd_marital_status) AS marital_status,
    AVG(hv.cd_purchase_estimate) AS average_purchase_estimate,
    COUNT(DISTINCT ra.total_refunds) AS total_store_refunds,
    COUNT(DISTINCT ir.return_count) AS total_item_returns,
    RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS overall_sales_rank
FROM ranked_sales ws
JOIN high_value_customers hv ON ws.ws_item_sk = hv.c_customer_sk
LEFT JOIN return_analysis ra ON hv.c_customer_sk = ra.STORES.s_store_sk
LEFT JOIN item_returns ir ON ws.ws_item_sk = ir.sr_item_sk
GROUP BY ws.ws_item_sk, ws.total_sales
HAVING SUM(ws.ws_sales_price) > 1000 OR COUNT(DISTINCT ir.return_count) > 5
ORDER BY overall_sales_rank;
