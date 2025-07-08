
WITH CustomerAggregate AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        LISTAGG(DISTINCT CONCAT(i.i_product_name, ' ', i.i_item_desc), '; ') WITHIN GROUP (ORDER BY i.i_product_name) AS purchased_items
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
    AVG(cagg.total_orders) AS avg_orders_per_customer,
    SUM(cagg.total_spent) AS total_revenue,
    LISTAGG(DISTINCT cagg.purchased_items, '; ') WITHIN GROUP (ORDER BY cagg.purchased_items) AS inventory_summary
FROM 
    CustomerAggregate cagg
    JOIN CustomerAddress ca ON cagg.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 10;
