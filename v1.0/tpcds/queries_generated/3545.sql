
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws_sales_price > 0
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ReturnPercentage AS (
    SELECT 
        cs.cc_call_center_sk,
        (SUM(COALESCE(CR.total_returned, 0)) / NULLIF(SUM(ss.total_sales), 0)) * 100 AS return_rate
    FROM 
        StoreSalesSummary ss
    LEFT JOIN 
        CustomerReturns CR ON ss.ss_store_sk = CR.sr_customer_sk
    GROUP BY 
        cs_call_center_sk
)
SELECT 
    site.web_site_id,
    total_sales,
    return_rate,
    ROW_NUMBER() OVER (ORDER BY return_rate DESC) AS site_rank
FROM 
    RankedSales site
JOIN 
    ReturnPercentage rp ON site.web_site_id = rp.web_site_id
WHERE 
    return_rate > 5
ORDER BY 
    return_rate DESC;
