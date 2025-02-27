
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_profit 
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
),
CustomerTransactions AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM TopItems)
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        ct.total_spent
    FROM 
        CustomerTransactions ct
    JOIN 
        customer c ON ct.c_customer_sk = c.c_customer_sk
    WHERE 
        ct.total_spent > (SELECT AVG(total_spent) FROM CustomerTransactions)
)
SELECT 
    hvc.c_customer_id, 
    hvc.total_spent, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_items_purchased
FROM 
    HighValueCustomers hvc
JOIN 
    web_sales ws ON hvc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    hvc.c_customer_id, 
    hvc.total_spent
ORDER BY 
    total_spent DESC;
