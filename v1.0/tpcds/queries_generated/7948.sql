
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number, ws.ws_sold_date_sk
),
SalesAggregates AS (
    SELECT 
        web_site_sk,
        SUM(total_sales) AS total_sales,
        AVG(total_sales) AS avg_sales,
        SUM(unique_customers) AS total_customers
    FROM 
        RankedSales
    GROUP BY 
        web_site_sk
),
SalesByPromotion AS (
    SELECT 
        ws.ws_promo_sk,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_promo_sk
)
SELECT 
    sa.web_site_sk,
    sa.total_sales,
    sa.avg_sales,
    sa.total_customers,
    sbp.promo_sales,
    (sa.total_sales - COALESCE(sbp.promo_sales, 0)) AS non_promo_sales
FROM 
    SalesAggregates sa
LEFT JOIN 
    SalesByPromotion sbp ON sa.web_site_sk = sbp.ws_promo_sk
ORDER BY 
    sa.total_sales DESC
LIMIT 10;
