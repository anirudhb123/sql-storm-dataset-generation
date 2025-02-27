
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.sold_date_sk, 
        ws.item_sk, 
        ws.quantity, 
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY ws.sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 20210101 AND 20211231
),
sales_summary AS (
    SELECT 
        sd.item_sk,
        SUM(sd.quantity) AS total_quantity_sold,
        SUM(sd.net_profit) AS total_net_profit,
        COUNT(sd.rn) AS sales_count
    FROM 
        sales_data sd
    WHERE 
        sd.rn <= 5  -- Limit to last 5 sales per item
    GROUP BY 
        sd.item_sk
),
aggregated_sales AS (
    SELECT 
        is.item_description AS description,
        ss.total_quantity_sold,
        ss.total_net_profit,
        ss.sales_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        sales_summary ss
    JOIN 
        item is ON is.i_item_sk = ss.item_sk
)
SELECT 
    a.description,
    a.total_quantity_sold,
    a.total_net_profit,
    a.rank,
    ic.ib_lower_bound,
    ic.ib_upper_bound,
    CASE 
        WHEN a.total_net_profit >= 1000 THEN 'High Value'
        WHEN a.total_net_profit >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    aggregated_sales a
LEFT JOIN 
    income_band ic ON a.total_net_profit BETWEEN ic.ib_lower_bound AND ic.ib_upper_bound
WHERE 
    a.sales_count > 2
ORDER BY 
    a.rank
LIMIT 10;
