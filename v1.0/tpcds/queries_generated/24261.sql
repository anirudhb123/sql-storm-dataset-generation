
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
outer_join_sales AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        COALESCE(s.ws_item_sk, 0) AS item_sk,
        COUNT(s.ws_order_number) AS order_count,
        SUM(r.total_net_profit) AS total_profit,
        SUM(s.ws_quantity) AS total_quantity
    FROM 
        address_info a
    LEFT JOIN 
        ranked_sales r ON r.ws_item_sk = 0 AND (r.total_quantity > 0 OR r.rank_sales < 5)
    LEFT JOIN 
        web_sales s ON s.ws_item_sk = r.ws_item_sk AND r.rank_sales = 1
    GROUP BY 
        a.ca_city, a.ca_state
),
final_result AS (
    SELECT 
        city,
        state,
        order_count,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS ranking
    FROM 
        outer_join_sales
    WHERE 
        total_profit IS NOT NULL AND total_profit > 1000
)
SELECT 
    f.city,
    f.state,
    f.order_count,
    f.total_profit,
    CASE 
        WHEN f.ranking BETWEEN 1 AND 10 THEN 'Top 10'
        WHEN f.ranking BETWEEN 11 AND 30 THEN 'Top 30'
        ELSE 'Others'
    END AS performance_band
FROM 
    final_result f
ORDER BY 
    f.order_count DESC, f.total_profit DESC
LIMIT 50;
