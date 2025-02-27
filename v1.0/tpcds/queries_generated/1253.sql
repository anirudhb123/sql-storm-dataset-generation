
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT CASE WHEN sr_return_quantity IS NOT NULL THEN sr_ticket_number END) AS store_returns_count,
        COUNT(DISTINCT CASE WHEN cr_return_quantity IS NOT NULL THEN cr_order_number END) AS catalog_returns_count,
        COUNT(DISTINCT CASE WHEN wr_return_quantity IS NOT NULL THEN wr_order_number END) AS web_returns_count
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sales_price) AS max_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cr.c_customer_id,
    cr.total_returns,
    COALESCE(sd.total_sales, 0) AS total_sales,
    CASE 
        WHEN cr.total_returns > 0 THEN 
            (cr.total_returns / NULLIF(sd.order_count, 0)) * 100 
        ELSE 0 
    END AS return_rate_percentage,
    CASE 
        WHEN sd.max_sales_price IS NOT NULL THEN 
            CONCAT('Max Price: ', FORMAT(sd.max_sales_price, 2))
        ELSE 
            'No Sales'
    END AS max_sales_price_info
FROM 
    CustomerReturns cr
LEFT JOIN 
    SalesData sd ON cr.c_customer_id = sd.customer_sk
WHERE 
    cr.total_returns > 5 OR sd.total_sales IS NULL
ORDER BY 
    cr.total_returns DESC, sd.total_sales DESC;
