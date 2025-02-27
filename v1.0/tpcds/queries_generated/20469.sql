
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country IS NOT NULL 
          AND w.web_country <> ''
),

AggregatedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),

CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(a.total_returned, 0) AS total_returned,
        COALESCE(a.return_count, 0) AS return_count,
        CASE 
            WHEN COALESCE(a.total_returned,0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        customer c
    LEFT JOIN 
        AggregatedReturns a ON c.c_customer_sk = a.cr_returning_customer_sk
)

SELECT 
    cs.c_customer_id,
    cs.return_status,
    ROUND(AVG(r.ws_sales_price), 2) AS avg_sales_price,
    SUM(r.ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT r.ws_order_number) AS unique_order_count
FROM 
    CustomerReturns cs
LEFT JOIN 
    web_sales r ON cs.c_customer_id = r.ws_bill_customer_sk
WHERE 
    cs.return_status = 'Returned' 
    OR (cs.return_status = 'Not Returned' AND r.ws_quantity IS NOT NULL)
GROUP BY 
    cs.c_customer_id, cs.return_status
HAVING 
    SUM(r.ws_quantity) > (SELECT AVG(ws_quantity) FROM web_sales WHERE ws_ship_date_sk IS NOT NULL)
ORDER BY 
    total_quantity_sold DESC NULLS LAST;
