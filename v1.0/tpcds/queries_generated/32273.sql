
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_item_sk IN (SELECT i_item_sk 
                        FROM item 
                        WHERE i_current_price > 20)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.order_count,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ts.total_sales) AS cumulative_sales,
    COUNT(DISTINCT ts.ws_item_sk) AS distinct_items_sold,
    MAX(ts.total_quantity) AS max_quantity_sold
FROM 
    SalesCTE ts
LEFT JOIN 
    customer c ON ts.ws_item_sk IN (SELECT ws_item_sk 
                                      FROM web_sales 
                                      WHERE ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ts.total_sales) > 5000
ORDER BY 
    cumulative_sales DESC
LIMIT 10;
