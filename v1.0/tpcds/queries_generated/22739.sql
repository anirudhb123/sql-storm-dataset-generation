
WITH demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
return_details AS (
    SELECT 
        sr_customer_sk, 
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    s.total_net_profit,
    s.order_count,
    r.return_count,
    r.total_return_amt,
    COALESCE(s.avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN r.return_count IS NULL THEN 'No returns'
        WHEN r.return_count > 5 THEN 'High return'
        ELSE 'Low return'
    END AS return_status
FROM customer c
LEFT JOIN demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN return_details r ON c.c_customer_sk = r.sr_customer_sk
WHERE 
    (d.cd_gender = 'F' AND d.cd_marital_status = 'M') 
    OR (d.cd_gender = 'M' AND d.cd_purchase_estimate > 10000)
ORDER BY 
    COALESCE(s.total_net_profit, 0) DESC,
    d.cd_gender,
    c.c_last_name ASC
FETCH FIRST 100 ROWS ONLY;
