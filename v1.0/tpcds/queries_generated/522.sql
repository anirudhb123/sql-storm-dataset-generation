
WITH SalesDetails AS (
    SELECT 
        s.ws_sold_date_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ws_ship_mode_sk ORDER BY SUM(s.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales s
    JOIN 
        ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        s.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        s.ws_sold_date_sk, s.ws_ship_mode_sk
)
SELECT 
    d.d_date AS sales_date,
    sd.total_quantity,
    sd.total_net_profit,
    CASE 
        WHEN sd.total_net_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('$', FORMAT(sd.total_net_profit, 2))
    END AS formatted_net_profit,
    sm.sm_type AS shipping_mode
FROM 
    SalesDetails sd
JOIN 
    date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON sd.profit_rank = 1
ORDER BY 
    d.d_date ASC
LIMIT 100;

-- To ensure we get a view of different levels of performance, we can also output rows where sales net profit 
-- is higher than the average for the quarter but ignores NULLs and includes additional filtering criteria.
WITH AvgQuarterlyProfit AS (
    SELECT 
        AVG(sd.total_net_profit) AS avg_profit
    FROM 
        SalesDetails sd
    GROUP BY 
        EXTRACT(YEAR FROM sd.ws_sold_date_sk), EXTRACT(QUARTER FROM sd.ws_sold_date_sk)
)
SELECT 
    d.d_date AS sales_date,
    sd.total_quantity,
    sd.total_net_profit,
    sm.sm_type AS shipping_mode
FROM 
    SalesDetails sd
JOIN 
    date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    sd.total_net_profit > (SELECT avg_profit FROM AvgQuarterlyProfit) 
    AND sd.total_net_profit IS NOT NULL
ORDER BY 
    sd.total_net_profit DESC;
