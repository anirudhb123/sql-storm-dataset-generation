
WITH sales_data AS (
    SELECT 
        SUM(cs_ext_sales_price) AS total_sales,
        cd_gender,
        ib_income_band_sk,
        d_year,
        sm_ship_mode_id
    FROM 
        catalog_sales
    JOIN 
        customer_demographics ON cs_bill_cdemo_sk = cd_demo_sk
    JOIN 
        income_band ON cd_purchase_estimate BETWEEN ib_lower_bound AND ib_upper_bound
    JOIN 
        date_dim ON cs_sold_date_sk = d_date_sk
    JOIN 
        ship_mode ON cs_ship_mode_sk = sm_ship_mode_sk
    WHERE 
        d_year = 2022
    GROUP BY 
        cd_gender, ib_income_band_sk, d_year, sm_ship_mode_id
),
ranked_sales AS (
    SELECT 
        gender,
        income_band_sk,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        (SELECT 
             cd_gender AS gender, 
             ib_income_band_sk, 
             SUM(total_sales) AS total_sales
         FROM sales_data
         GROUP BY cd_gender, ib_income_band_sk) AS aggregated_sales
)
SELECT 
    r.gender,
    r.income_band_sk,
    r.total_sales,
    r.sales_rank
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.gender, 
    r.sales_rank;
