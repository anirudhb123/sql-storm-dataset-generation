
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451870 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        customer_sales
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
customer_inventory AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.total_orders,
        COALESCE(i.total_quantity, 0) AS inventory_quantity,
        CASE 
            WHEN tc.total_orders > 10 THEN 'Frequent Buyer'
            WHEN tc.total_orders > 5 THEN 'Occasional Buyer'
            ELSE 'New Customer'
        END AS customer_type
    FROM 
        top_customers tc
    LEFT JOIN 
        inventory_summary i ON i.inv_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk)
)
SELECT *
FROM customer_inventory
WHERE rank <= 10
ORDER BY total_sales DESC;
