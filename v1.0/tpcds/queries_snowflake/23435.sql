
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_paid_inc_tax,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid_inc_tax DESC) AS sales_rank,
        CASE 
            WHEN ws_net_paid_inc_tax IS NULL THEN 0 
            ELSE ws_net_paid_inc_tax 
        END AS net_paid,
        CONCAT('Order Number: ', ws_order_number) AS order_info
    FROM 
        web_sales
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchasing_power_rank
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
high_value_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        hs.sales_amount,
        COALESCE(hvr.total_return_amount, 0) AS total_returns,
        (hs.sales_amount - COALESCE(hvr.total_return_amount, 0)) AS net_sales
    FROM 
        customer_info ci
    JOIN 
        (SELECT 
            r.ws_item_sk,
            SUM(r.ws_net_paid_inc_tax) AS sales_amount
         FROM 
            ranked_sales r
         WHERE 
            r.sales_rank = 1 
         GROUP BY 
            r.ws_item_sk) hs ON ci.c_customer_sk = hs.ws_item_sk
    LEFT JOIN 
        high_value_returns hvr ON ci.c_customer_sk = hvr.sr_customer_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.sales_amount AS "Total Sales",
    f.total_returns AS "Total Returns",
    f.net_sales AS "Net Sales",
    CASE 
        WHEN f.net_sales > 10000 THEN 'High Value Customer'
        WHEN f.net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    final_report f
WHERE 
    f.net_sales > (SELECT AVG(net_sales) FROM final_report)
ORDER BY 
    f.net_sales DESC
FETCH FIRST 10 ROWS ONLY;
