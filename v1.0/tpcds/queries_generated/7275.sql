
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(ws_item_sk) AS total_items_sold,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_net_profit,
        ss.total_orders,
        ss.total_items_sold,
        ss.avg_sales_price,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        customer c
    JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    tc.rank,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.total_items_sold,
    tc.avg_sales_price,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.rank;
