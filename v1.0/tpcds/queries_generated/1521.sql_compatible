
WITH DateRange AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
),

CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),

ReturnStats AS (
    SELECT
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),

CombinedStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_profit_per_order,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High Value'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM CustomerStats cs
    LEFT JOIN ReturnStats rs ON cs.c_customer_sk = rs.sr_returning_customer_sk
),

FinalOutput AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_profit_per_order,
        cs.total_returns,
        cs.total_return_amount,
        cs.customer_value_segment,
        DENSE_RANK() OVER (PARTITION BY cs.customer_value_segment ORDER BY cs.total_spent DESC) AS spend_rank
    FROM CombinedStats cs
)

SELECT
    d.d_date,
    fo.c_customer_sk,
    fo.total_orders,
    fo.total_spent,
    fo.total_returns,
    fo.customer_value_segment,
    CASE 
        WHEN fo.spend_rank <= 10 THEN 'Top 10 Spend'
        ELSE 'Other Customers'
    END AS customer_category
FROM DateRange d
JOIN FinalOutput fo ON fo.c_customer_sk IN (
    SELECT c_current_cdemo_sk FROM customer WHERE c_first_shipto_date_sk IN (SELECT d_date_sk FROM DateRange)
)
ORDER BY d.d_date, fo.total_spent DESC;
