
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS average_order_value,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        cs.average_order_value
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_customer_id = cs.c_customer_id
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
ReturnStatistics AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt) AS total_returned_value
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.total_orders,
    hvc.total_spent,
    hvc.average_order_value,
    COALESCE(rs.total_web_returns, 0) AS total_web_returns,
    COALESCE(rs.total_returned_value, 0) AS total_returned_value,
    CASE 
        WHEN hvc.total_spent > 1000 THEN 'VIP'
        WHEN hvc.total_spent > 500 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_category
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    ReturnStatistics rs ON hvc.c_customer_id = rs.ws_bill_customer_sk
ORDER BY 
    hvc.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
