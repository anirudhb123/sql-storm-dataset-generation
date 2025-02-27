
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_profit) AS total_net_profit,
        AVG(ws.net_paid) AS average_net_paid,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    JOIN 
        web_page wp ON ws.web_page_sk = wp.web_page_sk
    JOIN 
        customer c ON ws.ship_customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy IN (11, 12)) 
        AND (cd.gender = 'F' AND cd.marital_status = 'M')
    GROUP BY 
        w.warehouse_id
),
address_summary AS (
    SELECT 
        ca.city,
        COUNT(DISTINCT c.customer_sk) AS total_customers,
        AVG(cd.purchase_estimate) AS average_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.current_addr_sk = ca.address_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    GROUP BY 
        ca.city
),
promo_summary AS (
    SELECT 
        p.promo_id,
        COUNT(DISTINCT ws.order_number) AS orders_with_promo,
        SUM(ws.net_profit) AS total_promo_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON ws.promo_sk = p.promo_sk
    WHERE 
        p.discount_active = 'Y' AND p.start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        p.promo_id
)
SELECT 
    ss.warehouse_id,
    ss.total_quantity,
    ss.total_net_profit,
    ss.average_net_paid,
    asu.city,
    asu.total_customers,
    asu.average_purchase_estimate,
    ps.promo_id,
    ps.orders_with_promo,
    ps.total_promo_net_profit
FROM 
    sales_summary ss
JOIN 
    address_summary asu ON ss.total_quantity > 1000
JOIN 
    promo_summary ps ON ps.orders_with_promo > 5
ORDER BY 
    ss.total_net_profit DESC, asu.total_customers DESC;
