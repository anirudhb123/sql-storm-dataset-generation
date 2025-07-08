
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity AS total_quantity,
        ws.ws_net_profit AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MIN(d.d_date_sk) FROM date_dim d)
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity AS total_quantity,
        cs.cs_net_profit AS total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        sales_data sd ON cs.cs_sold_date_sk = sd.ws_sold_date_sk + 1 
                      AND cs.cs_item_sk = sd.ws_item_sk
),
aggregated_sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(total_quantity) AS total_quantity,
        SUM(total_net_profit) AS total_net_profit
    FROM sales_data
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
monthly_sales AS (
    SELECT 
        d.d_year,
        SUM(asd.total_quantity) AS quantity_sold,
        SUM(asd.total_net_profit) AS net_profit
    FROM 
        aggregated_sales_data asd
    JOIN 
        date_dim d ON asd.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ms.d_year,
    ms.quantity_sold,
    ms.net_profit,
    ROUND(NULLIF(ms.net_profit, 0) / NULLIF(ms.quantity_sold, 0), 2) AS average_net_profit_per_item,
    CASE 
        WHEN ms.quantity_sold > 1000 THEN 'High Volume'
        WHEN ms.quantity_sold BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    monthly_sales ms
JOIN 
    income_band ib ON (ms.quantity_sold BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound)
WHERE 
    ms.d_year >= 2020
ORDER BY 
    ms.d_year DESC 
LIMIT 10;
