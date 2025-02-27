
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COUNT(*) OVER (PARTITION BY ws.web_site_sk) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
SalesSummary AS (
    SELECT 
        r.web_site_sk,
        AVG(r.ws_sales_price) AS avg_sales_price,
        SUM(r.ws_sales_price) AS total_sales_value,
        MAX(r.ws_sales_price) as max_sales_price
    FROM 
        RankedSales r
    GROUP BY 
        r.web_site_sk
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
FinalReport AS (
    SELECT 
        ss.web_site_sk,
        ss.avg_sales_price,
        ss.total_sales_value,
        cr.total_returned_quantity,
        cr.return_count,
        CASE 
            WHEN cr.total_returned_quantity > 0 THEN 'Returned' 
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        SalesSummary ss
    LEFT JOIN 
        CustomerReturns cr ON cr.sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)

SELECT 
    fr.web_site_sk,
    fr.avg_sales_price,
    fr.total_sales_value,
    COALESCE(fr.total_returned_quantity, 0) AS total_returned_quantity,
    fr.return_count,
    fr.return_status
FROM 
    FinalReport fr
WHERE 
    fr.avg_sales_price > (SELECT AVG(avg_sales_price) FROM SalesSummary) 
    AND fr.return_count < (SELECT 0.1 * SUM(total_sales_value) FROM SalesSummary);

