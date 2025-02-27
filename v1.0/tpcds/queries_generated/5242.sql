
WITH SalesOverview AS (
    SELECT 
        d.d_year,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, s.s_store_name
),
SalesByCustomer AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
PromotionAnalysis AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count,
        SUM(ws.ws_ext_sales_price) AS promo_sales_total
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT
    so.d_year,
    so.s_store_name,
    so.total_quantity_sold,
    so.total_sales,
    so.avg_sales_price,
    sc.cd_gender,
    sc.cd_marital_status,
    sc.total_quantity AS customer_total_quantity,
    sc.unique_customers,
    pa.promo_sales_count,
    pa.promo_sales_total
FROM 
    SalesOverview so
JOIN 
    SalesByCustomer sc ON so.total_quantity_sold = sc.total_quantity
JOIN 
    PromotionAnalysis pa ON so.total_sales = pa.promo_sales_total
ORDER BY 
    so.d_year DESC, 
    so.total_sales DESC;
