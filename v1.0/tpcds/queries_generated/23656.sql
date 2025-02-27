
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
TopProfits AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_email_address) AS unique_emails,
        AVG(cd.cd_dep_count) AS avg_dependents
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.unique_emails,
        cs.avg_dependents
    FROM 
        CustomerStats cs
    INNER JOIN (
        SELECT 
            c_customer_sk, 
            COUNT(ws_order_number) AS order_count 
        FROM 
            web_sales 
        GROUP BY 
            c_customer_sk 
        HAVING 
            COUNT(ws_order_number) > 10
    ) orders ON cs.c_customer_sk = orders.c_customer_sk
)
SELECT 
    w.w_warehouse_id,
    SUM(ts.total_profit) AS warehouse_profit,
    COALESCE(SUM(hvc.unique_emails), 0) AS total_unique_emails,
    CASE 
        WHEN SUM(hvc.avg_dependents) IS NULL THEN 'No Dependents'
        ELSE CAST(SUM(hvc.avg_dependents) AS VARCHAR)
    END AS avg_dependents_info
FROM 
    warehouse w
LEFT JOIN 
    TopProfits ts ON w.w_warehouse_sk = ts.ws_item_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_customer_sk IS NULL OR hvc.c_customer_sk = w.w_warehouse_sk
GROUP BY 
    w.w_warehouse_id
HAVING 
    SUM(ts.total_profit) > (
        SELECT AVG(total_profit) 
        FROM TopProfits 
        WHERE total_profit IS NOT NULL
    )
ORDER BY 
    warehouse_profit DESC 
LIMIT 10;
