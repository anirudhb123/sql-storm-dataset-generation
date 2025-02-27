
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.customer_sk) AS unique_customers,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws.order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.sold_date_sk = dd.date_sk
    JOIN customer_demographics cd ON ws.bill_cdemo_sk = cd.demo_sk
    WHERE dd.year = 2023
    AND cd.gender = 'F'
    GROUP BY ws.web_site_id
),
promotion_summary AS (
    SELECT 
        p.promo_name,
        SUM(cs.net_profit) AS promo_net_profit,
        COUNT(DISTINCT cs.order_number) AS total_promo_orders
    FROM catalog_sales cs
    JOIN promotion p ON cs.promo_sk = p.promo_sk
    WHERE p.discount_active = 'Y'
    GROUP BY p.promo_name
),
final_summary AS (
    SELECT 
        sd.web_site_id,
        sd.total_net_profit,
        sd.unique_customers,
        sd.avg_sales_price,
        sd.total_orders,
        ps.promo_name,
        ps.promo_net_profit,
        ps.total_promo_orders
    FROM sales_data sd
    LEFT JOIN promotion_summary ps ON sd.total_net_profit > ps.promo_net_profit
)
SELECT 
    web_site_id,
    total_net_profit,
    unique_customers,
    avg_sales_price,
    total_orders,
    promo_name,
    promo_net_profit,
    total_promo_orders
FROM final_summary
ORDER BY total_net_profit DESC, total_orders DESC
LIMIT 10;
