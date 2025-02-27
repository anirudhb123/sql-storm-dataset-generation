
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_revenue,
        AVG(ws.net_profit) AS average_profit,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE ws.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws.web_site_id
),
PromotionsStats AS (
    SELECT 
        p.promo_name, 
        COUNT(DISTINCT ws.order_number) AS orders_promo,
        SUM(ws.ext_sales_price) AS revenue_from_promo
    FROM web_sales ws
    JOIN promotion p ON ws.promo_sk = p.p_promo_sk 
    WHERE ws.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY p.promo_name
)
SELECT 
    sd.web_site_id,
    sd.total_orders,
    sd.total_revenue,
    sd.average_profit,
    sd.unique_customers,
    ps.orders_promo,
    ps.revenue_from_promo
FROM SalesData sd
LEFT JOIN PromotionsStats ps ON sd.total_orders > 0
ORDER BY sd.total_revenue DESC
LIMIT 10;
