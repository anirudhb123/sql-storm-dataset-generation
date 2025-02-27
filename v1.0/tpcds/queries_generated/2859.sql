
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_web_site_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status, cd_income_band_sk
),
WarehouseData AS (
    SELECT 
        w.warehouse_sk,
        w.warehouse_id,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM warehouse w
    LEFT JOIN store s ON w.w_warehouse_sk = s.s_company_id
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY w.warehouse_sk, w.warehouse_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.gender,
    cd.marital_status,
    SUM(ws.total_sales) AS web_sales_total,
    wd.total_store_sales AS store_sales_total,
    wd.store_count AS associated_stores,
    CASE 
        WHEN cd.avg_purchase_estimate > 500 THEN 'High Value Customer'
        WHEN cd.avg_purchase_estimate BETWEEN 250 AND 500 THEN 'Moderate Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM customer c
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN RankedSales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN WarehouseData wd ON wd.warehouse_sk = c.c_current_addr_sk
WHERE c.c_birth_year BETWEEN 1980 AND 2000
AND (c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = 'Y')
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.gender, cd.marital_status, wd.total_store_sales, wd.store_count
HAVING SUM(ws.total_sales) > 1000
ORDER BY web_sales_total DESC
LIMIT 50;
