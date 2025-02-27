
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY w.w_warehouse_id
),
HighestSales AS (
    SELECT 
        w.w_warehouse_id,
        total_sales
    FROM RankedSales
    WHERE sales_rank = 1
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
)
SELECT 
    hs.w_warehouse_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COUNT(DISTINCT ci.c_customer_id) AS customer_count,
    SUM(hs.total_sales) AS revenue
FROM HighestSales hs
JOIN web_sales ws ON hs.w_warehouse_id = ws.ws_web_site_sk
JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
GROUP BY 
    hs.w_warehouse_id, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status
ORDER BY revenue DESC;
