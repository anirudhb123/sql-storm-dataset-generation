
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_name, i.i_item_desc
),

customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),

final_report AS (
    SELECT
        ss.w_warehouse_name,
        ss.i_item_desc,
        ss.total_quantity_sold,
        ss.total_sales_value,
        ss.average_net_profit,
        cs.order_count,
        cs.total_net_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON ss.total_sales_value > cs.total_net_profit
    ORDER BY 
        ss.total_sales_value DESC
)

SELECT 
    w.w_warehouse_name,
    i.i_item_desc,
    ss.total_quantity_sold,
    ss.total_sales_value,
    ss.average_net_profit,
    cs.order_count,
    cs.total_net_profit
FROM 
    final_report
WHERE 
    average_net_profit > 0 
ORDER BY 
    total_quantity_sold DESC, total_sales_value DESC;
