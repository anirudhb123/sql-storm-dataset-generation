
WITH RECURSIVE sales_tree AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_sold_date_sk,
        1 AS depth
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        ws.order_number,
        ws.item_sk,
        ws.sales_price,
        ws.quantity,
        ws.ext_sales_price,
        ws.sold_date_sk,
        st.depth + 1
    FROM 
        web_sales ws
    JOIN 
        sales_tree st ON ws.order_number = st.ws_order_number
    WHERE 
        st.depth < 5
),

aggregate_sales AS (
    SELECT 
        st.ws_order_number,
        SUM(st.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT st.ws_item_sk) AS distinct_items,
        COUNT(st.ws_quantity) AS total_quantity
    FROM 
        sales_tree st
    GROUP BY 
        st.ws_order_number
),

customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_profit,
    cs.orders_count,
    cs.avg_sales_price,
    COALESCE(as.total_sales, 0) AS total_sales_last_day,
    as.distinct_items
FROM 
    customer_stats cs
LEFT JOIN 
    aggregate_sales as ON cs.orders_count = as.total_quantity + cs.orders_count
WHERE 
    cs.total_profit > 1000
ORDER BY 
    total_profit DESC
LIMIT 100;

