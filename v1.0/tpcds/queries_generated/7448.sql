
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerPurchases c
    WHERE 
        c.order_count > 5
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ct.row_count,
    (
        SELECT COUNT(*)
        FROM customer_address ca
        WHERE ca.ca_state = 'CA'
    ) AS total_addresses_in_ca,
    (
        SELECT COUNT(DISTINCT p.p_item_id)
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    ) AS active_promotions
FROM 
    TopCustomers tc
JOIN 
    (SELECT COUNT(*) AS row_count FROM CustomerPurchases) ct ON TRUE
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
