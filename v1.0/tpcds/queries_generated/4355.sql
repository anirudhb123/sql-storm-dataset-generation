
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
OrderDetails AS (
    SELECT 
        cs.c_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_spent DESC) AS rank,
        cs.total_orders,
        cs.total_spent,
        i.i_item_desc
    FROM CustomerSales cs
    JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.customer_address_id,
        c.c_first_name,
        c.c_last_name,
        od.total_orders,
        od.total_spent,
        od.avg_order_value,
        RANK() OVER (ORDER BY od.total_spent DESC) AS customer_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN OrderDetails od ON cs.c_customer_sk = od.c_customer_sk
    WHERE cs.total_spent > 1000
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_orders,
    COALESCE(hvc.total_spent, 0) AS total_spent,
    CASE 
        WHEN hvc.customer_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_tier
FROM HighValueCustomers hvc
LEFT JOIN customer_address ca ON hvc.customer_address_id = ca.ca_address_id
WHERE ca.ca_state = 'CA'
ORDER BY hvc.total_spent DESC;
