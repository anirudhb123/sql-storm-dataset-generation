
WITH RankedSales AS (
    SELECT 
        w.warehouse_id, 
        s.store_id, 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_sold,
        DENSE_RANK() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws.ws_quantity) DESC) AS rank_by_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    GROUP BY 
        w.warehouse_id, s.store_id, i.i_item_id
),
TopItems AS (
    SELECT 
        warehouse_id, 
        store_id, 
        i_item_id
    FROM 
        RankedSales
    WHERE 
        rank_by_sales <= 5
),
SalesByDate AS (
    SELECT 
        d.d_date_id, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        TopItems ti ON ws.ws_item_sk = ti.i_item_id
    GROUP BY 
        d.d_date_id
)
SELECT 
    d.d_date,
    d.d_month_seq,
    d.d_year,
    sb.total_profit
FROM 
    date_dim d
JOIN 
    SalesByDate sb ON d.d_date_id = sb.d_date_id
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date;
