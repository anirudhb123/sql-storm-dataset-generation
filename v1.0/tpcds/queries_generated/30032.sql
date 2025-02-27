
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk IS NOT NULL -- Avoid NULL dates
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    sh.c_customer_sk, 
    sh.c_first_name || ' ' || sh.c_last_name AS full_name,
    sh.cd_gender,
    CASE 
        WHEN sh.total_profit IS NULL THEN 'No Sales' 
        ELSE FORMAT(sh.total_profit, 'C')
    END AS formatted_profit
FROM 
    SalesHierarchy sh
WHERE 
    sh.profit_rank = 1
ORDER BY 
    sh.total_profit DESC
LIMIT 10;

WITH RecentSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 
        AND dd.d_month_seq IN (1, 2, 3) -- First quarter
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        ir.total_quantity,
        ir.total_net_profit,
        RANK() OVER (ORDER BY ir.total_net_profit DESC) AS item_rank
    FROM 
        item i
    JOIN 
        RecentSales ir ON i.i_item_sk = ir.ws_item_sk
)
SELECT
    ti.i_item_id,
    ti.total_quantity,
    ti.total_net_profit,
    COALESCE(ti.total_net_profit, 0) AS net_profit_with_fallback
FROM 
    TopItems ti
WHERE 
    ti.item_rank <= 10
UNION ALL
SELECT 
    'Total',
    SUM(total_quantity),
    SUM(total_net_profit),
    COALESCE(SUM(total_net_profit), 0)
FROM 
    TopItems;
