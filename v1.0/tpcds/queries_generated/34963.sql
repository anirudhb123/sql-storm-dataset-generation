
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450010 AND 2450015
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) + s.total_quantity, 
        SUM(ws_net_profit) + s.total_profit
    FROM 
        web_sales s
    INNER JOIN 
        Sales_CTE cte ON s.ws_sold_date_sk = cte.ws_sold_date_sk - 1 
    WHERE 
        s.ws_item_sk = cte.ws_item_sk
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
Aggregated_Sales AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(ws.net_profit) AS total_net_profit,
        AVG(ws_ext_sales_price) AS avg_sales_price,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.net_profit) DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
            ws_item_sk, 
            COUNT(*) as sales_count
         FROM 
            web_sales
         WHERE 
            ws(ship_mode_sk IS NOT NULL) 
         GROUP BY 
            ws_item_sk) sales_counts ON ws.ws_item_sk = sales_counts.ws_item_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    a.c_customer_id,
    a.total_net_profit,
    a.avg_sales_price,
    COALESCE(sales_counts.sales_count, 0) AS sales_count,
    CASE 
        WHEN a.total_net_profit IS NULL THEN 'No Sales' 
        WHEN a.total_net_profit > 1000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS value_category
FROM 
    Aggregated_Sales a
LEFT JOIN 
    (SELECT 
        ws_item_sk, 
        COUNT(*) AS sales_count 
     FROM 
        web_sales 
     GROUP BY 
        ws_item_sk) sales_counts ON a.ws_item_sk = sales_counts.ws_item_sk
WHERE 
    a.total_net_profit IS NOT NULL
ORDER BY 
    a.total_net_profit DESC
LIMIT 50;
