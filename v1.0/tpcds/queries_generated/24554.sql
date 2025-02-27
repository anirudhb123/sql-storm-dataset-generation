
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        warehouse w 
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
Ranked_Sales AS (
    SELECT 
        warehouse_id,
        total_quantity,
        total_net_profit,
        total_sales,
        CASE 
            WHEN total_net_profit IS NULL THEN 'N/A'
            WHEN total_net_profit < 0 THEN 'Loss'
            ELSE 'Profit' 
        END AS profit_status
    FROM 
        Sales_CTE
),
Customer_Stats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(CASE 
                WHEN cd.cd_marital_status = 'M' AND cd.cd_gender = 'F' THEN 1 
                ELSE 0 
            END) AS married_female_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    R.warehouse_id,
    R.total_quantity,
    R.total_net_profit,
    R.total_sales,
    R.profit_status,
    CS.customer_count,
    CS.married_female_count,
    CASE 
        WHEN CS.max_purchase_estimate IS NULL THEN 'Unknown'
        ELSE CAST(CS.max_purchase_estimate AS VARCHAR) 
    END AS max_purchase_estimate_str
FROM 
    Ranked_Sales R
LEFT JOIN 
    Customer_Stats CS ON R.warehouse_id = (
        SELECT 
            w.w_warehouse_id
        FROM 
            warehouse w
        WHERE 
            w.w_warehouse_sk IN (
                SELECT 
                    DISTINCT ws.ws_warehouse_sk 
                FROM 
                    web_sales ws 
                WHERE 
                    ws.ws_quantity > 10
                ORDER BY 
                    ws.ws_net_profit DESC
                LIMIT 1
            )
    )
WHERE 
    R.rn = 1
ORDER BY 
    R.total_net_profit DESC
LIMIT 100;
