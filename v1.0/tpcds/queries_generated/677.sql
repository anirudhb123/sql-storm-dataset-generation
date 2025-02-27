
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.sales_price DESC) as rank
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq IN (5, 6)
    )
),
market_share AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss.order_number) as total_store_sales,
        SUM(ss.ext_sales_price) as total_sales_revenue
    FROM store_sales ss
    JOIN store s ON ss.store_sk = s.store_sk
    WHERE ss.sold_date_sk > (
        SELECT MAX(d_date_sk) - 30
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY s.s_store_sk
),
promotion_summary AS (
    SELECT 
        p.promo_sk,
        p.promo_name,
        SUM(ws.net_profit) as total_net_profit
    FROM promotion p
    JOIN web_sales ws ON p.promo_sk = ws.promo_sk
    GROUP BY p.promo_sk, p.promo_name
)
SELECT 
    wa.warehouse_name,
    COUNT(DISTINCT cs.item_sk) AS total_items_sold,
    SUM(wa.total_sales_revenue) AS total_revenue,
    COALESCE(ps.total_net_profit, 0) AS promo_net_profit,
    SUM(ranked_sales.ws_quantity) AS total_quantity_sold
FROM warehouse wa
LEFT JOIN market_share ms ON wa.warehouse_sk = ms.store_sk
LEFT JOIN ranked_sales rs ON rs.web_site_sk = wa.warehouse_sk
LEFT JOIN promotion_summary ps ON ps.promo_sk = rs.item_sk
GROUP BY wa.warehouse_name
HAVING SUM(ms.total_sales_revenue) > 10000 AND promo_net_profit > 1000
ORDER BY total_revenue DESC;
