
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        c.c_customer_id,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_dow,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND c.c_current_addr_sk IS NOT NULL
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        SUM(ws_sales_price * ws_quantity) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        SalesData
    WHERE 
        rn = 1
    GROUP BY 
        c_customer_id
),
AverageSpending AS (
    SELECT 
        AVG(total_spent) as avg_spent,
        AVG(order_count) as avg_orders
    FROM 
        TopCustomers
),
BestCustomers AS (
    SELECT 
        tc.c_customer_id,
        tc.total_spent,
        tc.order_count,
        COALESCE(bc.total_return_amount, 0) AS total_return_amount,
        tc.total_spent - COALESCE(bc.total_return_amount, 0) AS net_spent
    FROM 
        TopCustomers tc
    LEFT JOIN (
        SELECT 
            wr_returning_customer_sk AS customer_sk,
            SUM(wr_return_amt) AS total_return_amount
        FROM 
            web_returns
        GROUP BY 
            wr_returning_customer_sk
    ) bc ON tc.c_customer_id = bc.customer_sk
),
FinalReport AS (
    SELECT 
        bc.c_customer_id,
        bc.total_spent,
        bc.order_count,
        bc.total_return_amount,
        bc.net_spent,
        CASE 
            WHEN net_spent > 500 THEN 'High Value'
            WHEN net_spent BETWEEN 200 AND 500 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        BestCustomers bc
)

SELECT 
    fr.c_customer_id, 
    fr.total_spent, 
    fr.order_count, 
    fr.total_return_amount, 
    fr.net_spent,
    fr.customer_value
FROM 
    FinalReport fr
ORDER BY 
    fr.net_spent DESC;
