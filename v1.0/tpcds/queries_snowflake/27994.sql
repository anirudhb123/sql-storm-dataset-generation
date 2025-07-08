
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        LISTAGG(DISTINCT CONCAT(i.i_item_desc, ' (', ws.ws_quantity, ')'), ', ') AS purchased_items
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_spent DESC) AS rnk
    FROM 
        CustomerOrders c
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.order_count,
    c.total_spent,
    c.purchased_items
FROM 
    TopCustomers c
WHERE 
    c.rnk <= 10
ORDER BY 
    c.total_spent DESC;
