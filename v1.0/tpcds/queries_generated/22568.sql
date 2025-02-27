
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        AVG(sd.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT sd.ws_order_number) FILTER (WHERE sd.ws_net_profit > 0) AS positive_profit_orders,
        NULLIF(SUM(sd.ws_quantity), 0) AS total_quantity
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
),
ranked_items AS (
    SELECT 
        is.i_item_sk,
        is.total_sales,
        is.avg_profit,
        is.positive_profit_orders,
        (ROW_NUMBER() OVER (ORDER BY is.total_sales DESC) +
         COUNT(*) OVER () - 
         COUNT(NULLIF(is.total_sales, 0)) -
         COUNT(NULLIF(is.avg_profit, 0))) AS rank_value
    FROM 
        item_stats is
)
SELECT 
    i.i_item_sk,
    i.i_item_desc,
    r.total_sales,
    r.avg_profit,
    r.positive_profit_orders,
    r.rank_value,
    CASE 
        WHEN r.rank_value IS NULL THEN 'No Data'
        ELSE CASE 
            WHEN r.total_sales > 1000 THEN 'High Sales'
            WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END
    END AS sales_category
FROM 
    ranked_items r
JOIN 
    item i ON r.i_item_sk = i.i_item_sk
WHERE
    r.rank_value < 100
    OR (r.rank_value IS NOT NULL AND r.avg_profit IS NOT NULL)
ORDER BY 
    r.rank_value, i.i_item_sk
FETCH FIRST 50 ROWS ONLY;

WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        CAST(i.i_item_desc AS VARCHAR(255)) AS full_path,
        1 AS level
    FROM 
        item i
    WHERE 
        i.i_item_sk IS NOT NULL
    UNION ALL 
    SELECT 
        ih.i_item_sk,
        ih.i_item_desc,
        CONCAT(ih.full_path, ' -> ', ih.i_item_desc),
        ih.level + 1
    FROM 
        item_hierarchy ih
    WHERE 
        ih.level < 3
)
SELECT 
    ih.full_path,
    ih.level
FROM 
    item_hierarchy ih
WHERE 
    ih.level = 3
ORDER BY 
    ih.full_path DESC;

SELECT 
    area.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COUNT(DISTINCT i.i_item_id) AS unique_items,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-01-31') 
    AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date BETWEEN '2023-06-01' AND '2023-06-30'))
GROUP BY 
    area.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > (SELECT AVG(unique_customers) FROM (
        SELECT 
            COUNT(DISTINCT c.c_customer_id) AS unique_customers
        FROM 
            customer c
        LEFT JOIN 
            customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        GROUP BY 
            ca.ca_state
    ) AS summary)
ORDER BY 
    total_profit DESC;

SELECT 
    CASE 
        WHEN char_length(c.c_last_name) < 5 THEN 'Short Last Name'
        WHEN char_length(c.c_last_name) BETWEEN 5 AND 10 THEN 'Average Last Name'
        ELSE 'Long Last Name'
    END AS name_length_category,
    count(*) AS count
FROM 
    customer c
GROUP BY 
    name_length_category;

SELECT 
    DISTINCT wp.wp_url