
WITH RECURSIVE category_hierarchy AS (
    SELECT 
        c_category_id,
        c_category,
        0 AS depth
    FROM category 
    WHERE c_parent_category_id IS NULL
    UNION ALL
    SELECT 
        c.c_category_id,
        CONCAT(ch.c_category, ' -> ', c.c_category) AS c_category,
        ch.depth + 1
    FROM category c
    JOIN category_hierarchy ch ON c.c_parent_category_id = ch.c_category_id
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        w.w_warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
avg_sales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_ext_sales_price) AS avg_sales_price
    FROM 
        sales_data
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        sd.w_warehouse_name
    FROM 
        sales_data sd
    JOIN 
        avg_sales a ON sd.ws_item_sk = a.ws_item_sk
    WHERE 
        sd.ws_ext_sales_price > a.avg_sales_price
        AND sd.rank <= 5
),
customer_data AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        ca.ca_city,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY c_customer_sk) AS cust_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.ca_city,
    COUNT(DISTINCT hv.ws_order_number) AS total_orders,
    SUM(hv.ws_ext_sales_price) AS total_sales,
    STRING_AGG(DISTINCT CONCAT(ch.c_category_id, ': ', ch.c_category)) AS categories
FROM 
    customer_data cu
LEFT JOIN 
    high_value_items hv ON cu.c_customer_sk = hv.ws_item_sk
LEFT JOIN 
    category_hierarchy ch ON hv.ws_item_sk = ch.c_category_id
WHERE 
    cu.cust_rank <= 10
GROUP BY 
    cu.c_first_name, cu.c_last_name, cu.ca_city
HAVING 
    SUM(hv.ws_ext_sales_price) IS NOT NULL
ORDER BY 
    total_sales DESC;
