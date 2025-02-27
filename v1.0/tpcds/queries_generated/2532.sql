
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_ship_date_sk > (SELECT MAX(dd.d_date_sk) FROM date_dim dd WHERE dd.d_year = 2022)
),
AggregateSales AS (
    SELECT 
        r.web_site_sk,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_sales,
        COUNT(r.ws_order_number) AS order_count
    FROM 
        RankedSales AS r
    WHERE 
        r.rank_sales <= 10
    GROUP BY 
        r.web_site_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        a.web_site_sk,
        a.total_sales,
        a.order_count,
        ci.cd_gender,
        ci.cd_marital_status
    FROM 
        AggregateSales AS a
    JOIN 
        CustomerInfo AS ci ON ci.cd_income_band_sk IS NOT NULL
)
SELECT 
    si.web_site_sk,
    si.cd_gender,
    si.cd_marital_status,
    si.total_sales,
    si.order_count,
    COALESCE(si.total_sales / NULLIF(si.order_count, 0), 0) AS avg_sales_per_order
FROM 
    SalesInfo AS si
ORDER BY 
    si.total_sales DESC
LIMIT 20;
