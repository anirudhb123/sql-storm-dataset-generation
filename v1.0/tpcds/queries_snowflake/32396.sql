
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk, 
        0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),

SalesAggregates AS (
    SELECT 
        customer.c_customer_sk AS customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_net_paid
    FROM web_sales ws
    JOIN customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY customer.c_customer_sk
),

BestCustomers AS (
    SELECT 
        cha.c_first_name || ' ' || cha.c_last_name AS customer_name,
        sa.total_net_profit,
        sa.total_orders,
        RANK() OVER (ORDER BY sa.total_net_profit DESC) AS rank
    FROM SalesAggregates sa
    JOIN CustomerHierarchy cha ON sa.customer_id = cha.c_customer_sk
    WHERE sa.total_net_profit IS NOT NULL
),

FinalSelection AS (
    SELECT 
        bc.customer_name,
        bc.total_net_profit,
        bc.total_orders
    FROM BestCustomers bc
    WHERE bc.rank <= 10
)

SELECT 
    bc.customer_name,
    bc.total_net_profit,
    COALESCE(bc.total_orders, 0) AS total_orders,
    CASE 
        WHEN bc.total_net_profit > 1000 THEN 'High Value'
        ELSE 'Low Value' 
    END AS customer_value,
    CONCAT('Customer ', bc.customer_name, ' has a total profit of $', ROUND(bc.total_net_profit, 2)) AS profit_statement
FROM FinalSelection bc
ORDER BY bc.total_net_profit DESC;
