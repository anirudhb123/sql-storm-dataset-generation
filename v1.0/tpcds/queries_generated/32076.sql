
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        ss_item_sk,
        ss_ticket_number,
        1 AS level,
        ss_net_paid,
        ss_quantity
    FROM 
        store_sales
    WHERE 
        ss_quantity > 0
    
    UNION ALL
    
    SELECT 
        sh.ss_item_sk,
        sh.ss_ticket_number,
        oh.level + 1,
        sh.ss_net_paid,
        sh.ss_quantity
    FROM 
        store_sales sh
    JOIN 
        OrderHierarchy oh ON sh.ss_item_sk = oh.ss_item_sk AND sh.ss_ticket_number = oh.ss_ticket_number
    WHERE 
        oh.level < 10
),
CustomerRelatedSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_spent,
        cr.total_orders,
        RANK() OVER (ORDER BY cr.total_spent DESC) AS customer_rank
    FROM 
        CustomerRelatedSales cr
)
SELECT 
    ca.ca_city,
    SUM(ss.ss_quantity) AS total_items_sold,
    MAX(oh.level) AS max_order_level,
    AVG(tc.total_spent) AS average_spent
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    OrderHierarchy oh ON ss.ss_item_sk = oh.ss_item_sk
LEFT JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') AND 
    (tc.customer_rank IS NULL OR tc.customer_rank <= 10)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ss.ss_quantity) > 100
ORDER BY 
    total_items_sold DESC;
