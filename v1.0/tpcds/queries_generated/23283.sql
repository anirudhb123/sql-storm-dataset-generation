
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= 2450000  -- arbitrary date limit for sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        SUM(ss_sales_price) AS total_spent
    FROM customer
    JOIN store_sales ON c_customer_sk = ss_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    HAVING SUM(ss_sales_price) > 100000
),
top_items AS (
    SELECT 
        i_item_id,
        i_item_desc,
        AVG(i_current_price) AS avg_price
    FROM item
    WHERE i_rec_start_date < CURRENT_DATE
    GROUP BY i_item_id, i_item_desc
),
customer_activity AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(DISTINCT c.c_customer_id) DESC) AS city_rank
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
),
total_returns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt_inc_tax) AS return_value
    FROM catalog_returns
    WHERE cr_returned_date_sk IS NOT NULL
    GROUP BY cr_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    ti.i_item_id,
    ti.i_item_desc,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(su.total_sales) AS web_sales_total,
    COALESCE(tr.total_returns, 0) AS total_returns
FROM high_value_customers hvc
JOIN top_items ti ON ti.avg_price > 20
LEFT JOIN store_sales ss ON ss.ss_item_sk = ti.i_item_sk
LEFT JOIN sales_summary su ON su.ws_item_sk = ti.i_item_sk
LEFT JOIN total_returns tr ON tr.cr_item_sk = ti.i_item_sk
JOIN customer_activity ca ON ca.ca_city = 'New York'
WHERE hvc.total_spent > (
    SELECT AVG(total_spent) FROM high_value_customers
) OR hvc.total_spent IS NOT NULL
GROUP BY hvc.c_first_name, hvc.c_last_name, ti.i_item_id, ti.i_item_desc, tr.total_returns 
HAVING SUM(ss.ss_net_profit) > 5000
ORDER BY hvc.total_spent DESC, store_sales_profit DESC
LIMIT 10;
