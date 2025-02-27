
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.ticket_number,
        SUM(ss.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.sold_date_sk, ss.item_sk, ss.ticket_number
    HAVING 
        SUM(ss.ext_sales_price) > 100
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_amount) AS total_returned,
        COUNT(cr.returning_customer_sk) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
FilteredSales AS (
    SELECT 
        s.ticket_number,
        c.c_customer_id,
        COALESCE(cs.total_sales, 0) AS total_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        (COALESCE(cs.total_sales, 0) - COALESCE(cr.total_returned, 0)) AS net_sales
    FROM 
        SalesCTE cs
    LEFT JOIN 
        customer c ON cs.ticket_number = c.c_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.returning_customer_sk = c.c_customer_sk
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_returned,
    f.net_sales,
    d.d_date AS sale_date
FROM 
    FilteredSales f
JOIN 
    date_dim d ON d.d_date_sk = f.ticket_number
WHERE 
    f.net_sales > 0 
ORDER BY 
    f.net_sales DESC
LIMIT 100
OFFSET 0;
