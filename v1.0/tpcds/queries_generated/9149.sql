
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_net_profit) AS promo_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    cs.purchase_count,
    COALESCE(ss.total_quantity, 0) AS total_web_quantity,
    COALESCE(ss.total_net_profit, 0) AS total_web_net_profit,
    COALESCE(ps.promo_orders, 0) AS total_promo_orders,
    COALESCE(ps.promo_net_profit, 0) AS total_promo_net_profit
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT ws_item_sk FROM sales_summary))
LEFT JOIN 
    promotions ps ON ps.promo_orders > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
