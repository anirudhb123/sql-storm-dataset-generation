
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
ReturnData AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS returns_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
),
TopCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_orders,
        cp.total_quantity,
        cp.total_profit,
        rd.returns_count,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        ca.customer_count,
        CASE 
            WHEN cp.total_profit > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_segment
    FROM CustomerPurchase cp
    LEFT JOIN ReturnData rd ON cp.c_customer_sk = rd.sr_customer_sk
    LEFT JOIN CustomerAddress ca ON cp.c_customer_sk = ca.ca_address_sk
    WHERE cp.profit_rank <= 10
),
FinalOutput AS (
    SELECT 
        tc.c_customer_sk,
        tc.customer_segment,
        tc.total_orders,
        tc.total_quantity,
        ROUND(tc.total_profit - tc.total_return_amt, 2) AS net_profit,
        (CASE 
            WHEN (tc.total_orders IS NULL OR tc.total_orders = 0) THEN 'No Orders' 
            ELSE 'Orders Present' 
        END) AS order_status
    FROM TopCustomers tc
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(net_profit) AS average_net_profit,
    MAX(total_orders) AS max_orders,
    MIN(customer_count) AS min_customers_in_city
FROM FinalOutput
WHERE order_status = 'Orders Present'
GROUP BY customer_segment
ORDER BY average_net_profit DESC;
