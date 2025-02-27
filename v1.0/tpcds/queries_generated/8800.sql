
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_moy IN (6, 7)
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
PromotionImpact AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS orders_with_promo,
        SUM(ws.ws_ext_sales_price) AS total_sales_with_promo
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
)

SELECT 
    s.web_site_id,
    s.total_sales,
    s.avg_sales_price,
    s.total_orders,
    s.unique_customers,
    cd.cd_gender,
    cd.customer_count,
    w.total_warehouse_sales,
    p.promo_name,
    p.orders_with_promo,
    p.total_sales_with_promo
FROM 
    SalesSummary s
LEFT JOIN 
    CustomerDemographics cd ON s.total_orders > 50
LEFT JOIN 
    WarehouseSales w ON s.total_sales > 1000
LEFT JOIN 
    PromotionImpact p ON s.total_orders > 20
ORDER BY 
    s.total_sales DESC;
