
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_addr_sk
),
HighValueCustomers AS (
    SELECT 
        rcs.c_customer_sk,
        rcs.order_count,
        rcs.total_net_profit
    FROM 
        RankedCustomerSales rcs
    WHERE 
        rcs.profit_rank <= 10
),
ItemProfit AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS item_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hvc.total_net_profit, 0) AS total_net_profit,
    ip.item_profit,
    CASE 
        WHEN hvc.total_net_profit IS NULL THEN 'No Sales'
        WHEN ip.item_profit < 0 THEN 'Negative Profit'
        ELSE 'Positive Profit'
    END AS profit_description
FROM 
    customer c
    LEFT JOIN HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
    LEFT JOIN ItemProfit ip ON ip.ws_item_sk IN (
        SELECT DISTINCT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_customer_sk = c.c_customer_sk
    )
WHERE 
    (hvc.total_net_profit IS NOT NULL OR ip.item_profit IS NOT NULL)
ORDER BY 
    total_net_profit DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
