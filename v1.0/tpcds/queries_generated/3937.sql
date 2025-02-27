
WITH Ranked_Web_Sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), Sales_Summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), High_Profit_Customers AS (
    SELECT 
        s.c_customer_id,
        s.total_quantity,
        s.total_profit,
        s.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        Sales_Summary s
    JOIN 
        customer_demographics cd ON s.c_customer_id = cd.cd_demo_sk
    WHERE 
        s.total_profit > (SELECT AVG(total_profit) FROM Sales_Summary)
), CTE_Finished AS (
    SELECT 
        hpc.c_customer_id,
        hpc.total_quantity,
        hpc.total_profit,
        hpc.order_count,
        ROW_NUMBER() OVER (ORDER BY hpc.total_profit DESC) AS profit_rank
    FROM 
        High_Profit_Customers hpc
)

SELECT 
    f.c_customer_id,
    f.total_quantity,
    f.total_profit,
    f.order_count,
    f.profit_rank,
    COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
    COUNT(DISTINCT cr_order_number) AS total_catalog_returns
FROM 
    CTE_Finished f
LEFT JOIN 
    store_returns sr ON f.c_customer_id = sr.sr_customer_sk
LEFT JOIN 
    catalog_returns cr ON f.c_customer_id = cr.cr_returning_customer_sk
GROUP BY 
    f.c_customer_id,
    f.total_quantity,
    f.total_profit,
    f.order_count,
    f.profit_rank
ORDER BY 
    f.profit_rank
LIMIT 10;
