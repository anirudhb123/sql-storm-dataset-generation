
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023 
        AND c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_sk
),
product_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
top_products AS (
    SELECT 
        p.i_item_id,
        ps.total_quantity_sold,
        RANK() OVER (ORDER BY ps.total_quantity_sold DESC) AS rank
    FROM 
        product_summary ps 
    JOIN 
        item p ON ps.i_item_sk = p.i_item_sk
)
SELECT 
    ss.web_site_sk,
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_profit,
    tp.i_item_id,
    tp.total_quantity_sold
FROM 
    sales_summary ss
JOIN 
    top_products tp ON tp.rank <= 10
ORDER BY 
    ss.total_sales DESC, 
    tp.total_quantity_sold DESC;
