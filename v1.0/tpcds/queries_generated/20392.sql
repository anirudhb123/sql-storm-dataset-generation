
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_current_addr_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_store_sk
),
WebSalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM web_sales ws
    GROUP BY ws.web_site_sk
    HAVING MAX(ws.ws_sales_price) > 20
),
StoreSalesBonus AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS unique_tickets
    FROM store_sales
    GROUP BY ss_store_sk
    HAVING total_profit > 1000
)
SELECT 
    rc.c_customer_id,
    sa.ss_store_sk,
    COALESCE(sr.total_returned, 0) AS returns_count,
    COALESCE(wss.total_sales, 0) AS web_total_sales,
    CASE 
        WHEN rc.rnk = 1 THEN 'Top spender'
        WHEN rc.rnk IS NULL THEN 'No spending data'
        ELSE 'Other'
    END AS status,
    CASE 
        WHEN (NULLIF(wss.order_count, 0) IS NULL) AND (NULLIF(sr.total_returned, 0) IS NULL) THEN 'Inactivity'
        ELSE 'Active'
    END AS customer_activity
FROM RankedCustomers rc
LEFT JOIN AggregateReturns sr ON sr.sr_store_sk = rc.c_current_addr_sk
LEFT JOIN WebSalesSummary wss ON wss.web_site_sk = rc.c_current_addr_sk
LEFT JOIN StoreSalesBonus sa ON sa.ss_store_sk = rc.c_current_addr_sk
WHERE rc.rnk <= 10 OR rc.rnk IS NULL
ORDER BY rc.c_customer_id, returns_count DESC, web_total_sales DESC;
