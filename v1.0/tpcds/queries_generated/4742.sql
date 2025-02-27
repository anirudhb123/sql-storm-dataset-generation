
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_net_profit,
        r.total_quantity
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
SalesPerCustomer AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        sp.total_orders,
        sp.total_spent,
        CASE 
            WHEN sp.total_spent > 1000 THEN 'High Value'
            WHEN sp.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        SalesPerCustomer sp
    JOIN 
        customer c ON sp.c_customer_id = c.c_customer_id
)
SELECT 
    hvc.customer_value,
    COUNT(DISTINCT hvc.c_customer_id) AS customer_count,
    COALESCE(SUM(t.total_net_profit), 0) AS total_profit
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    TopSellingItems t ON hvc.c_customer_id IN (
        SELECT DISTINCT ws_bill_customer_sk
        FROM web_sales ws
        WHERE ws_item_sk IN (SELECT ws_item_sk FROM TopSellingItems)
    )
GROUP BY 
    hvc.customer_value
ORDER BY 
    customer_value DESC;
