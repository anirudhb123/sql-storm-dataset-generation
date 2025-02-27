
WITH sales_summary AS (
    SELECT 
        d.d_year,
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        d.d_year, w.w_warehouse_id
),
customer_segment AS (
    SELECT 
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ss.total_quantity_sold) AS quantity_by_segment,
        SUM(ss.total_sales) AS sales_by_segment,
        AVG(ss.average_net_profit) AS average_profit_by_segment
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.ws_item_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender, hd.hd_buy_potential
)
SELECT 
    cs.cd_gender,
    cs.hd_buy_potential,
    cs.quantity_by_segment,
    cs.sales_by_segment,
    cs.average_profit_by_segment
FROM 
    customer_segment cs
WHERE 
    cs.sales_by_segment > 1000
ORDER BY 
    cs.sales_by_segment DESC;
