
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451550
),
SalesStats AS (
    SELECT 
        rs.ws_item_sk,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sales_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_income_band_sk,
        ci.cd_marital_status,
        ci.buy_potential,
        ss.avg_sales_price,
        ss.total_sales,
        ss.sales_count
    FROM 
        CustomerInfo ci
    JOIN 
        SalesStats ss ON ci.c_customer_sk = ss.ws_item_sk
)
SELECT 
    sa.cd_gender,
    sa.cd_income_band_sk,
    AVG(sa.avg_sales_price) AS avg_sales_price,
    SUM(sa.total_sales) AS total_sales,
    COUNT(DISTINCT sa.c_customer_sk) AS unique_customers,
    COUNT(sa.sales_count) AS total_sales_count
FROM 
    SalesAnalysis sa
GROUP BY 
    sa.cd_gender, 
    sa.cd_income_band_sk
HAVING 
    AVG(sa.avg_sales_price) > 20
ORDER BY 
    total_sales DESC;
