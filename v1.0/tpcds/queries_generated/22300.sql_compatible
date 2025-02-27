
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighPerformers AS (
    SELECT 
        i_item_id, 
        i_item_desc, 
        ts.total_sales,
        CASE 
            WHEN ts.total_sales > (SELECT AVG(total_sales) FROM TotalSales) THEN 'High'
            ELSE 'Low'
        END AS performance_category
    FROM 
        item i
    JOIN 
        TotalSales ts ON i.i_item_sk = ts.ws_item_sk
),
CustomerReturning AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned,
        CASE 
            WHEN COUNT(DISTINCT sr_ticket_number) > 0 THEN 'Returning Customer'
            ELSE 'New Customer'
        END AS customer_status
    FROM 
        store_returns 
    JOIN 
        customer c ON sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
ArchivedReturns AS (
    SELECT 
        wr_return_order_number,
        SUM(wr_return_quantity) AS total_web_returns,
        wb.web_name
    FROM 
        web_returns wr
    JOIN 
        web_site wb ON wr.wr_web_page_sk = wb.web_site_sk
    GROUP BY 
        wr_return_order_number, wb.web_name
)
SELECT 
    h.i_item_id,
    h.i_item_desc,
    h.total_sales,
    h.performance_category,
    cr.c_customer_id,
    cr.return_count,
    cr.total_returned,
    cr.customer_status,
    ar.total_web_returns,
    ar.web_name
FROM 
    HighPerformers h
LEFT JOIN 
    CustomerReturning cr ON h.total_sales > 1000
LEFT JOIN 
    ArchivedReturns ar ON ar.total_web_returns > 5
WHERE 
    (cr.customer_status IS NOT NULL OR ar.total_web_returns IS NOT NULL)
    AND h.performance_category = 'High'
    AND (
        EXISTS (SELECT 1 FROM RecentSales r WHERE r.ws_item_sk = h.i_item_id AND r.sales_rank = 1)
        OR NOT EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = h.i_item_id)
    )
ORDER BY 
    h.total_sales DESC,
    cr.return_count DESC;
