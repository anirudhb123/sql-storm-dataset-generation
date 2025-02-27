
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr.order_number) AS total_catalog_returns,
        SUM(sr.return_amt_inc_tax) AS total_store_return_amount,
        SUM(cr.return_amt_inc_tax) AS total_catalog_return_amount,
        AVG(cd_dep_count) AS average_dependent_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ws_ext_tax) AS total_web_tax,
        COUNT(DISTINCT ws_order_number) AS total_web_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_store_returns,
    cs.total_catalog_returns,
    cs.total_store_return_amount,
    cs.total_catalog_return_amount,
    sd.total_web_sales,
    sd.total_web_tax,
    sd.total_web_orders,
    cs.average_dependent_count
FROM 
    CustomerSummary cs
LEFT JOIN 
    SalesData sd ON cs.c_customer_id = sd.customer_sk
WHERE 
    cs.total_store_returns > 0 OR cs.total_catalog_returns > 0
ORDER BY 
    cs.total_store_return_amount DESC, 
    cs.total_catalog_return_amount DESC
LIMIT 100;
