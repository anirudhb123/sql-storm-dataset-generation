
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
),
TotalReturns AS (
    SELECT 
        sr.return_count,
        sr.store_id,
        COALESCE(cr.refunded_cash, 0) AS refunded_cash
    FROM (
        SELECT 
            sr_store_sk AS store_id,
            COUNT(*) AS return_count
        FROM store_returns
        GROUP BY sr_store_sk
    ) sr
    LEFT JOIN (
        SELECT 
            sr_store_sk,
            SUM(sr_refunded_cash) AS refunded_cash
        FROM store_returns
        GROUP BY sr_store_sk
    ) cr ON sr.store_id = cr.sr_store_sk
),
EligibleCustomers AS (
    SELECT 
        ca.ca_address_id,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status,
        cd_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd_purchase_estimate IS NOT NULL
)
SELECT 
    ec.ca_address_id,
    ec.marital_status,
    SUM(COALESCE(rs.ws_net_profit, 0)) AS total_net_profit,
    COUNT(DISTINCT rs.ws_order_number) AS order_count,
    SUM(COALESCE(tr.return_count, 0)) AS total_returns,
    SUM(COALESCE(tr.refunded_cash, 0)) AS total_refunded
FROM EligibleCustomers ec
LEFT JOIN RankedSales rs ON ec.cd_purchase_estimate = rs.ws_quantity
LEFT JOIN TotalReturns tr ON ec.ca_address_id = tr.store_id
WHERE (total_refunded IS NULL OR total_refunded > 0)
GROUP BY ec.ca_address_id, ec.marital_status
HAVING SUM(COALESCE(rs.ws_net_profit, 0)) > 1000
ORDER BY total_net_profit DESC
FETCH FIRST 5 ROWS ONLY;
