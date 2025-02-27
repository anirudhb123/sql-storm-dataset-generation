
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders,
        SUM(sd.total_sales) AS total_spent,
        pi.promo_sales_count AS promo_influence,
        wi.total_inventory
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.web_site_sk
    LEFT JOIN 
        Promotions pi ON sd.ws_order_number IN (SELECT ws_order_number FROM web_sales)
    LEFT JOIN 
        WarehouseInfo wi ON wi.w_warehouse_sk = sd.web_site_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, pi.promo_sales_count, wi.total_inventory
)
SELECT 
    * 
FROM 
    FinalReport
WHERE 
    total_spent > 1000 AND
    total_orders > 5
ORDER BY 
    total_spent DESC
LIMIT 100;
