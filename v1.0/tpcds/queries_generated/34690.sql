
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_ship_date_sk

    UNION ALL

    SELECT 
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    INNER JOIN 
        SalesSummary s ON ss.ss_sold_date_sk = s.ws_ship_date_sk
    GROUP BY 
        ss.ss_sold_date_sk
),

RankedSales AS (
    SELECT 
        s.ws_ship_date_sk,
        s.total_quantity,
        s.total_net_profit,
        RANK() OVER (PARTITION BY s.ws_ship_date_sk ORDER BY s.total_net_profit DESC) AS rank
    FROM 
        SalesSummary s
)

SELECT 
    d.d_date AS report_date,
    COALESCE(r.total_quantity, 0) AS total_quantity,
    COALESCE(r.total_net_profit, 0) AS total_net_profit,
    r.rank
FROM 
    date_dim d
LEFT JOIN 
    RankedSales r ON d.d_date_sk = r.ws_ship_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date;
