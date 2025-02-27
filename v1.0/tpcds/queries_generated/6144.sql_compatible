
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year AS sales_year,
        c.c_gender AS customer_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        cd.cd_dep_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.c_gender, cd.cd_marital_status, ib.ib_income_band_sk, cd.cd_dep_count
),
AverageSales AS (
    SELECT 
        sales_year,
        customer_gender,
        cd_marital_status,
        ib_income_band_sk,
        AVG(total_sales) AS avg_sales,
        AVG(total_quantity) AS avg_quantity
    FROM 
        SalesData
    GROUP BY 
        sales_year, customer_gender, cd_marital_status, ib_income_band_sk
),
HighPerformers AS (
    SELECT 
        customer_gender,
        cd_marital_status,
        ib_income_band_sk,
        MAX(avg_sales) AS max_avg_sales
    FROM 
        AverageSales
    GROUP BY 
        customer_gender, cd_marital_status, ib_income_band_sk
)
SELECT 
    ap.customer_gender,
    ap.cd_marital_status,
    ap.ib_income_band_sk,
    a.avg_sales,
    a.avg_quantity,
    COUNT(*) AS total_items
FROM 
    HighPerformers ap
JOIN 
    AverageSales a ON ap.customer_gender = a.customer_gender 
                   AND ap.cd_marital_status = a.cd_marital_status 
                   AND ap.ib_income_band_sk = a.ib_income_band_sk
GROUP BY 
    ap.customer_gender, ap.cd_marital_status, ap.ib_income_band_sk, a.avg_sales, a.avg_quantity
ORDER BY 
    ap.customer_gender, ap.cd_marital_status, ap.ib_income_band_sk;
