
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_month_seq IN (1, 2, 3)  -- First quarter of the year
    GROUP BY 
        w.w_warehouse_id
),
TopWarehouses AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        rs.total_orders,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        warehouse w ON rs.w_warehouse_id = w.w_warehouse_id
    WHERE 
        rs.profit_rank <= 5  -- Top 5 warehouses by profit
)
SELECT 
    t.w_warehouse_id,
    t.w_warehouse_name,
    t.total_orders,
    t.total_profit,
    c.cc_name,
    cd.cd_gender,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
FROM 
    TopWarehouses t
JOIN 
    store s ON t.w_warehouse_id = s.s_store_id
JOIN 
    customer c ON s.s_store_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    t.w_warehouse_id, t.w_warehouse_name, c.cc_name, cd.cd_gender
ORDER BY 
    t.total_profit DESC;
