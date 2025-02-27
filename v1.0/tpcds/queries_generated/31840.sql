
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_customer_sk,
        1 AS level
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    UNION ALL
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity / 2 AS sr_return_quantity,
        sr_return_amt / 2 AS sr_return_amt,
        sr_customer_sk,
        level + 1
    FROM 
        CustomerReturns
    WHERE 
        sr_return_quantity > 1
),
DateSales AS (
    SELECT 
        d.d_date, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
    ORDER BY 
        total_return_amt DESC 
    LIMIT 10
),
SalesComparison AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
)
SELECT 
    d.d_date,
    ds.total_sales,
    COALESCE(tc.total_return_amt, 0) AS total_return_amt,
    sc.total_web_sales,
    sc.total_catalog_sales,
    sc.total_store_sales,
    ROUND((ds.total_sales - COALESCE(tc.total_return_amt, 0)), 2) AS net_sales,
    COUNT(DISTINCT c.c_customer_id) FILTER (WHERE c.c_current_addr_sk IS NOT NULL) AS active_customers
FROM 
    DateSales ds
JOIN 
    date_dim d ON ds.d_date = d.d_date
LEFT JOIN 
    TopCustomers tc ON tc.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_returned_date_sk = d.d_date_sk)
CROSS JOIN 
    SalesComparison sc
WHERE 
    ds.total_sales > 1000
GROUP BY 
    d.d_date, ds.total_sales, tc.total_return_amt, sc.total_web_sales, sc.total_catalog_sales, sc.total_store_sales
ORDER BY 
    d.d_date DESC;
