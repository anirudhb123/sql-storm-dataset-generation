
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2023 
      AND cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'S'
      AND ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.web_site_id
), warehouse_data AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
), promotion_data AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS total_promo_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    wd.total_inventory,
    pd.promo_id,
    pd.total_promo_sales
FROM sales_data sd
JOIN warehouse_data wd ON sd.web_site_id = wd.w_warehouse_id
LEFT JOIN promotion_data pd ON sd.web_site_id = pd.promo_id
ORDER BY sd.total_sales DESC
LIMIT 10;
