
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer AS c 
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_profit) > (
            SELECT AVG(ws_inner.ws_net_profit)
            FROM web_sales AS ws_inner
            GROUP BY ws_inner.ws_bill_customer_sk
        )
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        Sh.total_profit
    FROM 
        sales_hierarchy AS Sh
    JOIN 
        customer AS c ON Sh.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month = MONTH(CURRENT_DATE) AND cd.cd_gender = 'F'
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS warehouse_profit
    FROM 
        warehouse AS w
    JOIN 
        web_sales AS ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
    HAVING 
        SUM(ws.ws_net_profit) > 10000
)
SELECT 
    Sh.c_first_name,
    Sh.c_last_name,
    Sh.cd_marital_status,
    Sh.cd_gender,
    COALESCE(wi.warehouse_profit, 0) AS warehouse_profit
FROM 
    sales_hierarchy AS Sh
LEFT JOIN 
    warehouse_info AS wi ON Sh.c_customer_sk = wi.w_warehouse_sk
WHERE 
    Sh.total_profit > 5000
ORDER BY 
    Sh.total_profit DESC
LIMIT 100;
