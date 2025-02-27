
WITH SalesStats AS (
    SELECT 
        COALESCE(ss_store_sk, cs_call_center_sk, ws_ship_mode_sk) AS source_sk,
        CASE 
            WHEN ss_store_sk IS NOT NULL THEN 'store_sales'
            WHEN cs_call_center_sk IS NOT NULL THEN 'catalog_sales'
            ELSE 'web_sales'
        END AS source_type,
        SUM(COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) + COUNT(DISTINCT cs_order_number) + COUNT(DISTINCT ws_order_number) AS total_orders
    FROM store_sales ss
    FULL OUTER JOIN catalog_sales cs ON ss_ss_item_sk = cs.cs_item_sk
    FULL OUTER JOIN web_sales ws ON ss_ss_item_sk = ws.ws_item_sk
    GROUP BY 1, 2
),

TopProfits AS (
    SELECT 
        source_sk,
        source_type,
        total_profit,
        RANK() OVER (PARTITION BY source_type ORDER BY total_profit DESC) AS rank
    FROM SalesStats
)

SELECT 
    COALESCE(a.ca_city, b.w_city, c.cc_city) AS location,
    MAX(p.p_discount_active) AS has_active_discount,
    COUNT(DISTINCT d.d_date_id) AS total_days,
    SUM(CASE 
            WHEN T.rank <= 5 THEN T.total_profit 
            ELSE 0 
        END) AS top_5_profit_sum
FROM TopProfits T
LEFT JOIN customer_address a ON T.source_sk = a.ca_address_sk
LEFT JOIN warehouse b ON T.source_sk = b.w_warehouse_sk
LEFT JOIN call_center c ON T.source_sk = c.cc_call_center_sk
JOIN promotion p ON T.source_type = 
    CASE 
        WHEN 'store_sales' THEN 'store_promo'
        WHEN 'catalog_sales' THEN 'catalog_promo'
        ELSE 'web_promo'
    END
JOIN date_dim d ON (d.d_date_sk IN (SELECT DISTINCT ss_sold_date_sk FROM store_sales WHERE ss_store_sk = T.source_sk)
                    UNION ALL
                    SELECT DISTINCT cs_sold_date_sk FROM catalog_sales WHERE cs_call_center_sk = T.source_sk
                    UNION ALL
                    SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_ship_mode_sk = T.source_sk)
WHERE T.total_profit IS NOT NULL
GROUP BY 1
HAVING COUNT(DISTINCT d.d_date_id) > 0 and MAX(p.p_discount_active) IS NOT NULL
ORDER BY location DESC NULLS LAST;
