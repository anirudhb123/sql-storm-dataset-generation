
WITH detailed_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        i.i_item_desc,
        sd.d_day_name,
        sd.d_month_seq,
        ws.ws_ship_date_sk
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN 
        date_dim sd ON ws.ws_ship_date_sk = sd.d_date_sk
    WHERE 
        sd.d_year = 2023
), 
sales_summary AS (
    SELECT 
        ds.ws_order_number,
        COUNT(ds.ws_item_sk) AS total_items,
        SUM(ds.net_profit) AS total_net_profit,
        AVG(ds.ws_sales_price) AS avg_sales_price
    FROM 
        detailed_sales ds
    GROUP BY 
        ds.ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_items,
    ss.total_net_profit,
    ss.avg_sales_price
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON ss.ws_order_number IN (SELECT ss2.ws_order_number FROM detailed_sales ds WHERE ds.ws_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)) 
ORDER BY 
    ss.total_net_profit DESC 
LIMIT 10;

