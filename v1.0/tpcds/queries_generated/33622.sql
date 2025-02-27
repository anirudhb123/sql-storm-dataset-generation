
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    
    UNION ALL

    SELECT 
        sh.ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        sh.level + 1
    FROM 
        store_sales sh
    JOIN sales_hierarchy hier ON sh.ss_store_sk = hier.ss_store_sk
    WHERE 
        sh.ss_net_profit > 0
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category
),
order_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ah.ca_city AS city,
    ah.customer_count,
    AVG(is.avg_sales_price) AS average_item_price,
    SUM(os.total_sales) AS annual_sales,
    SUM(sh.total_profit) AS total_store_profit
FROM 
    address_info ah
LEFT JOIN 
    item_stats is ON is.order_count > 10
LEFT JOIN 
    order_summary os ON os.d_year = 2023
LEFT JOIN 
    sales_hierarchy sh ON ah.ca_address_sk = sh.ss_store_sk
WHERE 
    ah.customer_count IS NOT NULL
GROUP BY 
    ah.ca_city, ah.customer_count
HAVING 
    SUM(os.total_sales) > 5000
ORDER BY 
    average_item_price DESC;
