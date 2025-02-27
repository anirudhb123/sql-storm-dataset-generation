
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential 
    FROM 
        customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        cs.total_store_sales,
        cs.store_order_count,
        d.cd_gender,
        d.cd_marital_status,
        d.hd_income_band_sk,
        d.hd_buy_potential
    FROM 
        CustomerSales cs
    JOIN Demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    ss.c_customer_sk,
    ss.total_web_sales,
    ss.web_order_count,
    ss.total_store_sales,
    ss.store_order_count,
    d.ib_income_band_sk,
    d.hd_buy_potential,
    CASE 
        WHEN ss.total_web_sales > ss.total_store_sales THEN 'Web Dominant'
        ELSE 'Store Dominant'
    END AS sales_preference
FROM 
    SalesSummary ss
JOIN income_band d ON ss.hd_income_band_sk = d.ib_income_band_sk
WHERE 
    ss.web_order_count > 5 OR ss.store_order_count > 5
ORDER BY 
    ss.total_web_sales DESC, ss.total_store_sales DESC
LIMIT 100;
