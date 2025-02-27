
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price >= (SELECT AVG(ws_sales_price) FROM web_sales)
),
HighReturningItems AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned 
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
    HAVING 
        SUM(cr_return_quantity) > 100
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amt) AS total_return_amt,
        CASE 
            WHEN SUM(cr_return_amt) > 500 THEN 'High'
            WHEN SUM(cr_return_amt) BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM 
        catalog_returns cr
    WHERE 
        cr_return_quantity IS NOT NULL
    GROUP BY 
        cr.returning_customer_sk
),
FinalAnalysis AS (
    SELECT 
        c.c_customer_id,
        rd.total_return_amt,
        di.d_current_week,
        ra.ws_item_sk,
        ra.rank_sales
    FROM 
        customer c
    JOIN 
        CustomerReturns rd ON c.c_customer_sk = rd.returning_customer_sk
    LEFT JOIN 
        RankedSales ra ON ra.ws_item_sk IN (SELECT item.sk FROM HighReturningItems hi WHERE hi.total_returned > 10)
    JOIN 
        date_dim di ON di.d_date_sk = (SELECT DISTINCT sr_returned_date_sk FROM store_returns sr WHERE sr_customer_sk = c.c_customer_sk)
    WHERE 
        rd.return_count > 0
        AND ra.rank_sales <= 5
        AND di.d_current_month = '1'
        AND (rd.total_return_amt IS NOT NULL OR rd.total_return_amt IS NULL)
)
SELECT 
    f.c_customer_id,
    f.total_return_amt,
    CONCAT('Customer ', f.c_customer_id, ' has a return amount of ', COALESCE(f.total_return_amt, 'N/A')) AS return_summary
FROM 
    FinalAnalysis f
ORDER BY 
    f.total_return_amt DESC;
