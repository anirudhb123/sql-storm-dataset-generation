
WITH Profit_Margin_CTE AS (
    SELECT 
        ws.ws_item_sk,
        (ws.ws_sales_price - ws.ws_wholesale_cost) AS profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_item_sk, ws.ws_sales_price, ws.ws_wholesale_cost
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        (cs.cs_sales_price - cs.cs_wholesale_cost) AS profit
    FROM 
        catalog_sales cs
    JOIN 
        Profit_Margin_CTE pm ON cs.cs_item_sk = pm.ws_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs.cs_item_sk, cs.cs_sales_price, cs.cs_wholesale_cost
),
Sales_Data AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(ss.ss_net_profit, 0) AS store_profit,
        COALESCE(ws.ws_net_profit, 0) AS web_profit,
        AVG(pm.profit) AS avg_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        Profit_Margin_CTE pm ON ss.ss_item_sk = pm.ws_item_sk OR ws.ws_item_sk = pm.ws_item_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, ss.ss_net_profit, ws.ws_net_profit
)
SELECT 
    sd.gender,
    SUM(sd.store_profit) AS total_store_profit,
    SUM(sd.web_profit) AS total_web_profit,
    COUNT(sd.c_customer_sk) AS number_of_customers,
    AVG(sd.avg_profit) AS avg_profit_per_item
FROM 
    Sales_Data sd
WHERE 
    (sd.store_profit > 0 OR sd.web_profit > 0) AND 
    (sd.gender IS NOT NULL)
GROUP BY 
    sd.gender
ORDER BY 
    total_store_profit DESC, total_web_profit DESC;
