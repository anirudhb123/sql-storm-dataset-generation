
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cs.cs_item_sk, cs.cs_order_number
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_paid
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.cs_item_sk = item.i_item_sk
    WHERE 
        sales.rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_paid,
    COALESCE(SUM(ws.ws_quantity), 0) AS web_quantity,
    COALESCE(SUM(ws.ws_net_paid), 0) AS web_net_paid
FROM 
    TopItems ti
LEFT JOIN 
    web_sales ws ON ti.i_item_sk = ws.ws_item_sk
GROUP BY 
    ti.i_item_id, ti.i_item_desc, ti.total_quantity, ti.total_net_paid
ORDER BY 
    ti.total_net_paid DESC;
