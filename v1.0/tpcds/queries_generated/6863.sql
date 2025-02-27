
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        rs.total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.profit_rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_net_profit,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS average_order_value
FROM 
    TopItems ti
LEFT JOIN 
    web_sales ws ON ti.i_item_id = ws.ws_item_sk
GROUP BY 
    ti.i_item_id, ti.i_product_name, ti.total_net_profit
ORDER BY 
    total_net_profit DESC;
