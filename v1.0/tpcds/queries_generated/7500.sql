
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sale_price,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_orders,
        ss.total_profit,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_sale_price
    FROM 
        customer cs
    JOIN 
        SalesSummary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.profit_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_profit,
    tc.total_quantity,
    tc.total_sales,
    tc.avg_sale_price,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.ws_bill_customer_sk)
ORDER BY 
    tc.total_profit DESC;
