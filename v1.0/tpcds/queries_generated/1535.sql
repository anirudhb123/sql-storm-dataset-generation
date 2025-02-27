
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_returned_date_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr.returned_date_sk) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns sr ON c.c_customer_sk = sr.sr_customer_sk AND sr.rnk <= 3
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(DISTINCT sr.returned_date_sk) >= 1
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
ReturnStats AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(total_sold, 0) AS total_sold,
        COALESCE(total_sales, 0) AS total_sales,
        COALESCE(avg_price, 0) AS avg_price,
        COUNT(DISTINCT sr.returned_date_sk) AS return_occurrences
    FROM 
        item i
    LEFT JOIN 
        ItemSales is ON i.i_item_sk = is.ws_item_sk
    LEFT JOIN 
        store_returns sr ON is.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    i.i_item_id,
    i.i_item_desc,
    r.return_count,
    r.total_sales,
    r.avg_price,
    CASE 
        WHEN return_occurrences > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    TopCustomers r
JOIN 
    ReturnStats i ON r.return_count >= 1
WHERE 
    r.return_count >= 1
ORDER BY 
    r.return_count DESC, i.total_sales DESC
LIMIT 100;
