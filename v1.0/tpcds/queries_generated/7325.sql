
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr_order_number) AS total_catalog_returns,
        COUNT(DISTINCT wr_order_number) AS total_web_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ws_net_profit) AS total_web_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CatalogSalesData AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs_net_profit) AS total_catalog_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
StoreSalesData AS (
    SELECT 
        ss_customer_sk AS customer_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    cr.c_customer_id,
    COALESCE(sd.total_web_sales, 0) AS total_web_sales,
    COALESCE(cd.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(ssd.total_store_sales, 0) AS total_store_sales,
    cr.total_store_returns,
    cr.total_catalog_returns,
    cr.total_web_returns
FROM 
    CustomerReturns cr
LEFT JOIN 
    SalesData sd ON cr.c_customer_id = sd.customer_sk
LEFT JOIN 
    CatalogSalesData cd ON cr.c_customer_id = cd.customer_sk
LEFT JOIN 
    StoreSalesData ssd ON cr.c_customer_id = ssd.customer_sk
ORDER BY 
    cr.c_customer_id;
