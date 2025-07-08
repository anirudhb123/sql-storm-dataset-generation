
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_web_sales) AS total_web_sales_by_state,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_state,
        SUM(cs.total_store_sales) AS total_store_sales_by_state
    FROM 
        CustomerSales AS cs
    JOIN 
        customer_address AS ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer AS c WHERE c.c_customer_id = cs.c_customer_id)
    GROUP BY 
        ca.ca_state
),
SalesMetrics AS (
    SELECT 
        ca_state,
        total_web_sales_by_state,
        total_catalog_sales_by_state,
        total_store_sales_by_state,
        (total_web_sales_by_state + total_catalog_sales_by_state + total_store_sales_by_state) AS total_sales,
        ROUND((total_web_sales_by_state / NULLIF(total_sales, 0)) * 100, 2) AS web_sales_percentage,
        ROUND((total_catalog_sales_by_state / NULLIF(total_sales, 0)) * 100, 2) AS catalog_sales_percentage,
        ROUND((total_store_sales_by_state / NULLIF(total_sales, 0)) * 100, 2) AS store_sales_percentage
    FROM 
        SalesByState
)
SELECT 
    ca_state,
    total_web_sales_by_state,
    total_catalog_sales_by_state,
    total_store_sales_by_state,
    total_sales,
    web_sales_percentage,
    catalog_sales_percentage,
    store_sales_percentage
FROM 
    SalesMetrics
ORDER BY 
    total_sales DESC
LIMIT 10;
