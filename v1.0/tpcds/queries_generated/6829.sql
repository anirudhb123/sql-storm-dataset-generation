
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS ranking
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit
FROM 
    SalesData sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE 
    sd.ranking = 1
ORDER BY 
    sd.total_profit DESC
LIMIT 10;
