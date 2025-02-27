
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.bill_customer_sk AS customer_sk,
        SUM(ws.net_profit) AS total_profit,
        1 AS level
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.bill_customer_sk

    UNION ALL

    SELECT 
        sr.returning_customer_sk,
        SUM(sr.net_loss) AS total_profit,
        level + 1
    FROM 
        store_returns sr
    JOIN 
        SalesHierarchy sh ON sr.refunded_customer_sk = sh.customer_sk
    GROUP BY 
        sr.returning_customer_sk
),
MaxSales AS (
    SELECT 
        customer_sk,
        MAX(total_profit) AS max_profit
    FROM 
        SalesHierarchy
    GROUP BY 
        customer_sk
)

SELECT 
    c.c_customer_id,
    COALESCE(s.total_profit, 0) AS total_web_profit,
    COALESCE(r.total_loss, 0) AS total_store_loss,
    COALESCE(s.max_profit, 0) - COALESCE(r.total_loss, 0) AS net_profit,
    CASE 
        WHEN COALESCE(s.max_profit, 0) > COALESCE(r.total_loss, 0) THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS profit_status
FROM 
    customer c
LEFT JOIN 
    (SELECT 
        customer_sk,
        SUM(total_profit) AS total_profit, 
        MAX(total_profit) AS max_profit
    FROM 
        SalesHierarchy 
    GROUP BY 
        customer_sk) s ON c.c_customer_sk = s.customer_sk
LEFT JOIN 
    (SELECT 
        returning_customer_sk,
        SUM(net_loss) AS total_loss
    FROM 
        store_returns 
    GROUP BY 
        returning_customer_sk) r ON c.c_customer_sk = r.returning_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    net_profit DESC NULLS LAST;
