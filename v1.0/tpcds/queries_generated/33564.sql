
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
address_summary AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city
),
high_sales_items AS (
    SELECT 
        item.i_item_id,
        item.i_current_price,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss 
    JOIN item ON ss.ss_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_current_price 
    HAVING 
        SUM(ss.ss_net_profit) > 10000
)
SELECT 
    a.ca_city,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales,
    hsi.i_item_id,
    hsi.i_current_price,
    hsi.total_net_profit
FROM 
    address_summary a
LEFT JOIN sales_summary ss ON a.c_customer_sk = ss.ws_item_sk
LEFT JOIN high_sales_items hsi ON ss.ws_item_sk = hsi.i_item_id
WHERE 
    a.customer_count > 10
ORDER BY 
    a.ca_city, total_sales DESC
LIMIT 100;
