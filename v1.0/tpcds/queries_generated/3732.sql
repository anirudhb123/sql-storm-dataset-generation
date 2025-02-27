
WITH sales_summary AS (
    SELECT 
        d.d_year,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        d.d_year, i.i_item_id
),
top_items AS (
    SELECT 
        d.d_year, 
        i.i_item_id, 
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit,
        ss.total_orders,
        CASE 
            WHEN ss.total_profit IS NULL THEN 'No Profit')
            ELSE FORMAT(ss.total_profit / NULLIF(ss.total_orders, 0), 'C', 'en-US') 
        END AS average_profit_per_order
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.i_item_id = i.i_item_id
    JOIN 
        date_dim d ON ss.d_year = d.d_year
    WHERE 
        ss.rank <= 10
)
SELECT 
    ti.d_year,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_profit,
    ti.total_orders,
    COALESCE(ti.average_profit_per_order, 'No Data') AS avg_profit_per_order
FROM 
    top_items ti
LEFT JOIN 
    customer c ON ti.total_orders = c.c_customer_sk
WHERE 
    c.c_customer_id IS NOT NULL
ORDER BY 
    ti.d_year, ti.total_profit DESC;
