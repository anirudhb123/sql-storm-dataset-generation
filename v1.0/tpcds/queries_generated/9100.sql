
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231 
        OR cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
), SalesSummary AS (
    SELECT 
        hd.hd_income_band_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(total_web_sales) AS total_web_sales,
        SUM(total_catalog_sales) AS total_catalog_sales,
        SUM(web_order_count) AS total_web_orders,
        SUM(catalog_order_count) AS total_catalog_orders
    FROM 
        CustomerSales
    GROUP BY 
        hd_income_band_sk, cd_gender, cd_marital_status
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.cd_gender,
    s.cd_marital_status,
    s.customer_count,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_web_orders,
    s.total_catalog_orders
FROM 
    SalesSummary AS s
JOIN 
    income_band AS ib ON s.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_lower_bound, s.customer_count DESC;
