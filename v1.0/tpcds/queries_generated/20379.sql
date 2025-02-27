
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
address_counts AS (
    SELECT
        ca_address_sk,
        COUNT(*) AS num_customers
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_address_sk
),
store_info AS (
    SELECT 
        s_store_sk,
        s_store_name,
        COALESCE(SUM(ss_net_profit), 0) AS total_store_profit,
        COALESCE(SUM(ss_quantity), 0) AS total_store_quantity
    FROM store
    LEFT JOIN store_sales ON s_store_sk = ss_store_sk
    GROUP BY s_store_sk, s_store_name
),
top_customers AS (
    SELECT 
        c_customer_id,
        ROW_NUMBER() OVER (ORDER BY NULLIF(MAX(ws_net_profit), 0) DESC) AS customer_rank
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    WHERE ws_net_profit IS NOT NULL
    GROUP BY c_customer_id
),
item_details AS (
    SELECT 
        i_item_id,
        i_item_desc,
        i_current_price,
        i_brand,
        ib_lower_bound,
        ib_upper_bound
    FROM item
    LEFT JOIN income_band ON i_item_sk = ib_income_band_sk
)
SELECT
    s.store_name,
    i.item_desc,
    ic.item_id,
    ic.current_price,
    COALESCE(l.total_quantity, 0) AS sold_quantity,
    COALESCE(l.total_profit, 0) AS sold_profit,
    a.num_customers AS num_customers_at_address,
    c.customer_id,
    CASE 
        WHEN rc.rank_profit = 1 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category,
    CASE 
        WHEN cct.customer_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    store_info s
JOIN item_details i ON s.store_sk = i.item_sk
LEFT JOIN ranked_sales l ON i.item_sk = l.ws_item_sk
LEFT JOIN address_counts a ON a.ca_address_sk = customer.c_current_addr_sk
LEFT JOIN top_customers cct ON c.customer_id = cct.c_customer_id
WHERE 
    (l.total_profit IS NOT NULL AND l.total_profit > 0) 
    OR (a.num_customers IS NULL AND i.current_price < 10)    
ORDER BY 
    s.store_name ASC, sold_profit DESC;
