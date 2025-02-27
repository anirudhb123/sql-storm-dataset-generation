
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_store_returns,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_catalog_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_month_seq
)
SELECT 
    m.d_month_seq,
    m.total_web_sales,
    m.total_catalog_sales,
    COALESCE(m.total_web_sales, 0) + COALESCE(m.total_catalog_sales, 0) AS total_sales,
    COALESCE(c.total_store_returns, 0) + COALESCE(c.total_catalog_returns, 0) AS total_returns,
    CASE 
        WHEN (COALESCE(m.total_web_sales, 0) + COALESCE(m.total_catalog_sales, 0)) > 0 
        THEN ((COALESCE(c.total_store_returns, 0) + COALESCE(c.total_catalog_returns, 0)) 
              / (COALESCE(m.total_web_sales, 0) + COALESCE(m.total_catalog_sales, 0))) * 100 
        ELSE 0
    END AS return_percentage
FROM 
    MonthlySales m
LEFT JOIN 
    CustomerReturns c ON c.c_customer_id = (SELECT c_customer_id FROM customer ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    m.d_month_seq;
