
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        store s
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
    GROUP BY 
        s.s_store_sk, s.s_store_name
), 
HighSalesStores AS (
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_sales
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.sales_rank <= 10
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_day,
        cd.cd_birth_month,
        cd.cd_birth_year,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
CombinedSales AS (
    SELECT 
        hs.s_store_name,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM 
        HighSalesStores hs
    JOIN 
        catalog_sales cs ON hs.s_store_sk = cs.cs_ship_mode_sk
    GROUP BY 
        hs.s_store_name
)

SELECT 
    cs.s_store_name,
    cs.total_orders,
    cs.total_sales_amount,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.cd_birth_month = 12 THEN 'Birthday Cheer!'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    CombinedSales cs
FULL OUTER JOIN 
    CustomerDemographics cd ON cs.total_orders = (SELECT COUNT(*) FROM web_sales WHERE ws_ship_customer_sk = cd.c_customer_sk)
WHERE 
    cd.hd_income_band_sk IS NOT NULL OR cs.total_sales_amount IS NULL
ORDER BY 
    cs.total_sales_amount DESC NULLS LAST;
