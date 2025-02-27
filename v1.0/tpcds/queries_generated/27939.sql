
WITH FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = 12 AND c.c_birth_day BETWEEN 15 AND 31
),
AggregatedSales AS (
    SELECT 
        c.c_city, 
        c.c_state,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM FilteredCustomers c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_city, c.c_state
),
RankedSales AS (
    SELECT 
        city, 
        state, 
        total_sales, 
        total_orders,
        DENSE_RANK() OVER (PARTITION BY state ORDER BY total_sales DESC) AS sales_rank
    FROM AggregatedSales
)
SELECT 
    city, 
    state, 
    total_sales, 
    total_orders, 
    sales_rank
FROM RankedSales
WHERE sales_rank <= 5 
ORDER BY state, sales_rank;
