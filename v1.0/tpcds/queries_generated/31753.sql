
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales 
    WHERE 
        ws_net_profit > 0

    UNION ALL 

    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cte.level + 1
    FROM 
        web_sales ws 
    JOIN 
        SalesCTE cte ON ws.ws_order_number = cte.ws_order_number 
    WHERE 
        ws.ws_item_sk = cte.ws_item_sk AND 
        cte.level < 5
),
MaxProfits AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL AND
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    COUNT(s.ws_order_number) AS orders_count,
    COALESCE(SUM(s.ws_net_profit), 0) AS total_net_profit,
    MAX(m.total_profit) AS highest_item_profit,
    CASE 
        WHEN SUM(s.ws_net_profit) > 1000 THEN 'High Roller'
        WHEN SUM(s.ws_net_profit) BETWEEN 500 AND 1000 THEN 'Moderate'
        ELSE 'Low Roller'
    END AS customer_category
FROM 
    FilteredCustomers f
LEFT JOIN 
    web_sales s ON f.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    MaxProfits m ON s.ws_item_sk = m.ws_item_sk
GROUP BY 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status
HAVING 
    COUNT(s.ws_order_number) > 5
ORDER BY 
    total_net_profit DESC,
    f.c_last_name,
    f.c_first_name
LIMIT 10;
