
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_ranking
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
), 
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY ws.ws_item_sk
), 
returns_data AS (
    SELECT 
        sr.str_return_quantity,
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.str_return_quantity
), 
final_data AS (
    SELECT 
        sd.ws_item_sk,
        coalesce(sd.total_quantity_sold, 0) AS total_sales,
        coalesce(sd.total_profit, 0) AS total_profit,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        COALESCE(rd.total_returns, 0) AS total_returns,
        CASE WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL ELSE (COALESCE(rd.total_return_amount, 0) / NULLIF(sd.total_profit, 0)) END AS return_on_sales_ratio
    FROM sales_data sd
    FULL OUTER JOIN returns_data rd ON sd.ws_item_sk = rd.sr_item_sk
)
SELECT 
    fd.ws_item_sk,
    fd.total_sales,
    fd.total_profit,
    fd.total_return_amount,
    fd.total_returns,
    fd.return_on_sales_ratio
FROM final_data fd
WHERE 
    (fd.total_profit > 1000 OR fd.total_sales < 50)
    AND (fd.return_on_sales_ratio IS NULL OR fd.return_on_sales_ratio < 0.1)
ORDER BY fd.return_on_sales_ratio DESC NULLS LAST;
