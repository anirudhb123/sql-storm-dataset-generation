
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_ext_discount_amt, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_tax > (
        SELECT AVG(ws_inner.ws_net_paid_inc_tax)
        FROM web_sales ws_inner 
        WHERE ws_inner.ws_item_sk = ws.ws_item_sk
    )
), 
address_data AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count 
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
), 
promotion_summary AS (
    SELECT 
        p.p_promotions_sk, 
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promotions_sk
)
SELECT 
    a.ca_city, 
    a.ca_state,
    COUNT(DISTINCT sd.ws_item_sk) AS popular_items_count, 
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(ps.total_profit) AS total_promo_profit,
    CASE 
        WHEN COUNT(DISTINCT a.customer_count) IS NULL 
        THEN 'No Customers' 
        ELSE 'Has Customers'
    END AS customer_status    
FROM address_data a
LEFT JOIN sales_data sd ON a.customer_count > 0
LEFT JOIN promotion_summary ps ON ps.promo_sales_count > 10
GROUP BY a.ca_city, a.ca_state
HAVING SUM(sd.ws_net_profit) IS NOT NULL 
   AND COUNT(sd.ws_item_sk) > 1
ORDER BY total_quantity_sold DESC, a.ca_state ASC NULLS LAST;
