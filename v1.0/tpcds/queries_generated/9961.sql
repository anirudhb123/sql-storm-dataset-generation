
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
PromotionData AS (
    SELECT 
        p.p_promo_id,
        SUM(cs.cs_quantity) AS total_promotion_quantity,
        SUM(cs.cs_ext_sales_price) AS total_promotional_sales
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_sales,
    sd.average_net_profit,
    pd.total_promotion_quantity,
    pd.total_promotional_sales,
    ws.warehouse_id,
    ws.total_store_quantity,
    ws.total_store_sales
FROM 
    SalesData sd
LEFT JOIN 
    PromotionData pd ON sd.web_site_id = pd.p_promo_id
LEFT JOIN 
    WarehouseSales ws ON sd.web_site_id = ws.warehouse_id
WHERE 
    sd.total_sales > 10000
ORDER BY 
    sd.total_sales DESC;
