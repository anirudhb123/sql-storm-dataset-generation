
WITH annual_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        COUNT(DISTINCT ws_item_sk) AS items_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1980 AND cd.cd_marital_status = 'S'
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
shipping_modes AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_ship_mode_sk) AS shipping_count,
        SUM(ws.ws_ext_sales_price) AS shipping_revenue
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_spent,
    cs.orders_count,
    cs.items_count,
    COALESCE(ss.shipping_revenue, 0) AS total_shipping_revenue,
    COALESCE(as.total_sales, 0) AS total_sales_rank
FROM 
    customer_stats cs
LEFT JOIN 
    shipping_modes ss ON cs.c_customer_sk = ss.sm_ship_mode_id
LEFT JOIN 
    annual_sales as ON cs.c_customer_sk = as.ws_item_sk
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC, cs.orders_count DESC
FETCH FIRST 50 ROWS ONLY;
