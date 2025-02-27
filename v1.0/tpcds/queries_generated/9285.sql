
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS average_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        sd.average_net_profit
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    COALESCE(SUM(ws_ext_discount_amt), 0) AS total_discounts,
    COALESCE(SUM(ws_ext_tax), 0) AS total_taxes,
    COALESCE(SUM(ws_ext_ship_cost), 0) AS total_shipping_cost,
    COALESCE(AVG(ws_net_paid_inc_tax), 0) AS avg_net_paid_incl_tax
FROM 
    top_items t
LEFT JOIN 
    web_sales ws ON t.ws_item_sk = ws.ws_item_sk
GROUP BY 
    t.i_item_id, t.i_item_desc;
