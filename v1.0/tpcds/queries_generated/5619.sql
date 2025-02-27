
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        c.c_gender,
        d.d_year,
        SUM(ws.ws_net_profit) OVER(PARTITION BY d.d_year, c.c_gender ORDER BY ws.ws_sold_date_sk) AS cum_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
GenderSales AS (
    SELECT 
        c_gender,
        d_year,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        SalesData
    GROUP BY 
        c_gender, d_year
)
SELECT 
    g.d_year,
    g.c_gender,
    g.total_quantity,
    g.total_profit,
    g.avg_profit,
    ROW_NUMBER() OVER(PARTITION BY g.d_year ORDER BY g.total_profit DESC) AS profit_rank
FROM 
    GenderSales g
WHERE 
    g.total_profit > 10000
ORDER BY 
    g.d_year, profit_rank
LIMIT 100;
