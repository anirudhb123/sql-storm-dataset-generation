
WITH RankedReturns AS (
    SELECT 
        cr_item_sk, 
        cr_order_number, 
        ROW_NUMBER() OVER (PARTITION BY cr_item_sk ORDER BY cr_returned_date_sk DESC) AS rn,
        SUM(cr_return_quantity) OVER (PARTITION BY cr_item_sk) AS total_returned,
        COUNT(DISTINCT cr_refunded_customer_sk) OVER (PARTITION BY cr_item_sk) AS unique_customers
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity IS NOT NULL
        AND cr_returned_date_sk > 0
),
RecentReturns AS (
    SELECT 
        rr.cr_item_sk,
        rr.cr_order_number,
        COALESCE(rr.total_returned, 0) AS total_returned,
        rr.unique_customers,
        CASE 
            WHEN rr.rn = 1 THEN 'Most Recent Return' 
            ELSE 'Previous Returns' 
        END AS return_category
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn <= 5
),
ShippedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
    GROUP BY 
        ws_item_sk
),
CombinedData AS (
    SELECT 
        rr.cr_item_sk,
        rr.return_category,
        rr.total_returned,
        COALESCE(ss.total_profit, 0) AS total_profit
    FROM 
        RecentReturns rr
    LEFT JOIN 
        ShippedSales ss ON rr.cr_item_sk = ss.ws_item_sk
)
SELECT 
    cd.cr_item_sk,
    cd.return_category,
    cd.total_returned,
    cd.total_profit,
    CASE 
        WHEN cd.total_profit > 0 THEN 'Profitable'
        WHEN cd.total_profit = 0 AND cd.total_returned > 0 THEN 'Returned Product Only'
        ELSE 'Non-Profitable Item'
    END AS profitability_status,
    (SELECT COUNT(DISTINCT ws_web_page_sk)
     FROM web_sales
     WHERE ws_item_sk = cd.cr_item_sk) AS web_page_count,
    EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = cd.cr_item_sk AND ss.ss_net_paid < 0) AS has_negative_paid
FROM 
    CombinedData cd
WHERE 
    cd.total_returned > (SELECT AVG(total_returned) FROM RecentReturns)
ORDER BY 
    cd.total_profit DESC, cd.total_returned DESC;
