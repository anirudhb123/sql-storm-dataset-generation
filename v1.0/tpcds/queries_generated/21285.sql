
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_quantity,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopReturnedItems AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS num_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        COUNT(*) > (SELECT AVG(total_returns) FROM CustomerReturns)
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_id,
        d.d_dow,
        COUNT(ws_order_number) AS total_orders,
        COALESCE(SUM(ws_sales_price), 0) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws_sales_price) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, d.d_dow
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS unique_web_orders,
    (SELECT COUNT(*) FROM TopReturnedItems tr WHERE tr.sr_item_sk IN 
        (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)) AS top_returned_item_count
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (c.c_birth_month = 10 AND c.c_birth_day = 31) OR 
    (c.c_birth_month IS NULL AND c.c_birth_year IS NOT NULL) 
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    SUM(COALESCE(ss.ss_net_paid, 0)) > 10000
ORDER BY 
    total_web_sales DESC, unique_web_orders DESC
LIMIT 50
UNION ALL
SELECT 
    NULL AS c_first_name,
    NULL AS c_last_name,
    NULL AS ca_city,
    SUM(ss_net_paid) AS total_net_paid,
    NULL AS total_web_sales,
    NULL AS unique_web_orders,
    NULL AS top_returned_item_count
FROM 
    store_sales
WHERE 
    ss_sold_date_sk >= (SELECT MAX(ws_sold_date_sk) FROM web_sales)
AND 
    ss_sold_date_sk <= (SELECT MIN(ws_sold_date_sk) FROM web_sales);
