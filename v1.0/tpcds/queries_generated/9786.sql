
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 -- Filter for the current year
        AND cd.cd_gender = 'F' -- Female customers
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ir.i_item_id,
        ir.i_item_desc,
        rs.total_quantity_sold,
        rs.total_sales,
        rs.total_discount,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        item ir ON rs.ws_item_sk = ir.i_item_sk
    WHERE 
        rs.item_rank <= 10 -- Get top 10 items by profit
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.total_discount,
    ti.total_profit,
    SUM(ws.ws_net_paid) AS total_net_paid
FROM 
    TopItems ti
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
WHERE 
    ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
GROUP BY 
    ti.i_item_id, ti.i_item_desc, ti.total_quantity_sold, ti.total_sales, ti.total_discount, ti.total_profit
ORDER BY 
    ti.total_profit DESC;
