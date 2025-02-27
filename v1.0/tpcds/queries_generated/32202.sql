
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        0 AS Level
    FROM 
        customer c
    WHERE 
        c.c_birth_year IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_birth_year,
        ch.Level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        sd.total_quantity,
        sd.avg_net_profit,
        sd.total_sales_price
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    ORDER BY 
        sd.total_quantity DESC
    LIMIT 10
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_year,
    COALESCE(ti.total_quantity, 0) AS total_quantity,
    COALESCE(ti.avg_net_profit, 0) AS avg_net_profit,
    COALESCE(ti.total_sales_price, 0) AS total_sales_price
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    TopItems ti ON ch.c_customer_sk = ti.i_item_sk
WHERE 
    (ch.c_birth_year > 1970 AND ch.Level = 0)
ORDER BY 
    ch.c_birth_year DESC;
