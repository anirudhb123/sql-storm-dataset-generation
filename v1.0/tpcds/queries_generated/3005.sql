
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank,
        COALESCE(CAST(SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS VARCHAR), 'unknown_domain') AS email_domain
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
MaxReturns AS (
    SELECT
        sr.returning_customer_sk,
        SUM(sr.return_quantity) AS total_returned_items
    FROM store_returns AS sr
    GROUP BY sr.returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnDetails AS (
    SELECT
        cs.cs_bill_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS distinct_returned_items,
        COUNT(*) AS total_returns
    FROM catalog_sales AS cs
    LEFT JOIN store_returns AS sr ON cs.cs_order_number = sr.sr_ticket_number AND cs.cs_bill_customer_sk = sr.sr_customer_sk
    GROUP BY cs.cs_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.purchase_rank,
    cs.email_domain,
    COALESCE(mr.total_returned_items, 0) AS total_returned_items,
    ws.total_net_profit,
    rd.distinct_returned_items,
    rd.total_returns
FROM CustomerStats cs
LEFT JOIN MaxReturns mr ON cs.c_customer_sk = mr.returning_customer_sk
LEFT JOIN WebSalesSummary ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN ReturnDetails rd ON cs.c_customer_sk = rd.cs_bill_customer_sk
WHERE cs.cd_marital_status = 'M' 
AND (ws.total_net_profit IS NULL OR ws.total_net_profit > 1000)
ORDER BY cs.purchase_rank, total_returned_items DESC;
