
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        w.warehouse_sk,
        w.warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS site_rank
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    GROUP BY ws.web_site_sk, ws.web_name, w.warehouse_sk, w.warehouse_name
),
HighPerformingSites AS (
    SELECT 
        web_site_sk, 
        web_name, 
        total_net_profit,
        total_orders
    FROM SalesSummary
    WHERE site_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    h.web_name,
    h.total_net_profit,
    h.total_orders,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(cr.total_returned_amount) AS total_returns_amount,
    AVG(cr.total_returns) AS avg_returns_per_customer
FROM HighPerformingSites h
JOIN CustomerDetails c ON c.c_customer_sk IN (
    SELECT ws.ws_bill_customer_sk FROM web_sales ws
    WHERE ws.ws_web_site_sk = h.web_site_sk
) 
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
GROUP BY h.web_name, h.total_net_profit, h.total_orders
HAVING SUM(cr.total_returned_amount) IS NOT NULL
ORDER BY h.total_net_profit DESC;
