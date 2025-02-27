
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
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
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_id
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(d.customer_count) AS total_customers,
    SUM(d.total_web_sales) AS total_web_sales,
    SUM(d.total_catalog_sales) AS total_catalog_sales,
    SUM(d.total_store_sales) AS total_store_sales
FROM 
    Demographics d
JOIN 
    income_band ib ON d.ib_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    d.cd_gender, d.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    d.cd_gender, d.cd_marital_status, ib.ib_income_band_sk;
