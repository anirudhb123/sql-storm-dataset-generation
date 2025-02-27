
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_quarter_seq IN (1, 2) 
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.total_net_profit
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit
FROM 
    customer ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
WHERE 
    ci.c_birth_year BETWEEN 1990 AND 2000
ORDER BY 
    ti.total_net_profit DESC;
