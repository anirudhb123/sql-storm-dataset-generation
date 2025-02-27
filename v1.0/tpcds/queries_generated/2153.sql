
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 AND d_dom = 31)
),
CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_spent,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS customer_rank
    FROM 
        CustomerPurchase cp
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    rs.ws_quantity,
    rs.ws_order_number
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedSales rs ON tc.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = rs.ws_order_number)
WHERE 
    tc.customer_rank <= 10
    AND (rs.ws_quantity IS NULL OR rs.ws_quantity > 0)
ORDER BY 
    tc.total_spent DESC,
    rs.ws_quantity DESC;
