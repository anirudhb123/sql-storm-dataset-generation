
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        sales_data sd ON cs.cs_sold_date_sk = sd.ws_sold_date_sk + 1 
                      AND cs.cs_item_sk = sd.ws_item_sk
    GROUP BY 
        cs.cs_sold_date_sk, cs.cs_item_sk
),
monthly_sales AS (
    SELECT 
        d.d_year,
        SUM(sd.total_quantity) AS quantity_sold,
        SUM(sd.total_net_profit) AS net_profit
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    d_year,
    quantity_sold,
    net_profit,
    ROUND(net_profit / NULLIF(quantity_sold, 0), 2) AS average_net_profit_per_item,
    CASE 
        WHEN quantity_sold > 1000 THEN 'High Volume'
        WHEN quantity_sold BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    monthly_sales
JOIN 
    income_band ib ON (quantity_sold BETWEEN ib_lower_bound AND ib_upper_bound)
WHERE 
    d_year >= 2020
ORDER BY 
    d_year DESC 
LIMIT 10;
