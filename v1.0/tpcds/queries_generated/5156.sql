
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    ds.c_customer_id,
    ds.total_sales,
    d.cd_gender,
    d.cd_marital_status,
    COUNT(DISTINCT ds.online_orders) AS online_order_count,
    COUNT(DISTINCT ds.catalog_orders) AS catalog_order_count,
    COUNT(DISTINCT ds.store_orders) AS store_order_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    CustomerSales ds
JOIN 
    Demographics d ON ds.c_customer_id = d.cd_demo_sk
JOIN 
    income_band ib ON d.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ds.total_sales > 1000
GROUP BY 
    ds.c_customer_id, ds.total_sales, d.cd_gender, d.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
HAVING 
    COUNT(DISTINCT ds.online_orders) > 5 OR COUNT(DISTINCT ds.catalog_orders) > 3
ORDER BY 
    ds.total_sales DESC
LIMIT 100;
