
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity + sd.ws_quantity,
        ws.ws_net_profit + sd.ws_net_profit,
        sd.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesData sd ON ws.ws_sold_date_sk = sd.ws_sold_date_sk + 1
    WHERE
        sd.level < 5
)

SELECT 
    item.i_item_id,
    item.i_item_desc,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY SUM(sd.ws_net_profit) DESC) AS rank
FROM 
    SalesData sd
JOIN 
    item ON sd.ws_item_sk = item.i_item_sk
GROUP BY 
    item.i_item_id, 
    item.i_item_desc
HAVING 
    SUM(sd.ws_net_profit) > (
        SELECT 
            AVG(ws_ext_sales_price) 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    )
ORDER BY 
    total_net_profit DESC
LIMIT 10;

SELECT 
    sd1.i_item_id,
    sd1.total_quantity_sold,
    sd1.total_net_profit
FROM (
    SELECT 
        i.i_item_id,
        SUM(sd.ws_quantity) AS total_quantity_sold,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
) AS sd1
WHERE 
    sd1.total_quantity_sold > (
        SELECT COALESCE(MAX(sd2.total_quantity_sold) * 0.5, 0) 
        FROM (
            SELECT 
                SUM(ws_quantity) AS total_quantity_sold
            FROM 
                web_sales
            WHERE 
                ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
            GROUP BY 
                ws_item_sk
        ) AS sd2
    )
ORDER BY 
    sd1.total_net_profit DESC
LIMIT 5;
