
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        total_profit > 1000
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank <= 10
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(sr.total_returns, 0) AS total_store_returns,
    COALESCE(wr.total_returns, 0) AS total_web_returns,
    hvc.total_profit,
    (CASE 
        WHEN hvc.total_orders > 0 THEN hvc.total_profit / hvc.total_orders 
        ELSE 0 
    END) AS avg_profit_per_order
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    StoreReturns sr ON sr.sr_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = hvc.c_customer_id)
LEFT JOIN 
    WebReturns wr ON wr.wr_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = hvc.c_customer_id)
ORDER BY 
    hvc.total_profit DESC;
