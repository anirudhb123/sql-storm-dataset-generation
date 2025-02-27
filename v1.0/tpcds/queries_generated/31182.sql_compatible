
WITH RECURSIVE sales_summary AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM
        web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        ws.bill_customer_sk
),
top_customers AS (
    SELECT
        ss.bill_customer_sk,
        ss.total_net_profit
    FROM
        sales_summary ss
    WHERE
        ss.rank <= 10
),
returns_summary AS (
    SELECT
        wr.returning_customer_sk,
        SUM(wr.return_amt) AS total_return_amount
    FROM
        web_returns wr
    GROUP BY
        wr.returning_customer_sk
),
customer_addresses AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM
        customer_address ca
    WHERE
        ca.ca_state = 'CA'
),
final_summary AS (
    SELECT 
        tc.bill_customer_sk,
        tc.total_net_profit,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        ca.ca_city
    FROM
        top_customers tc
    LEFT JOIN returns_summary rs ON tc.bill_customer_sk = rs.returning_customer_sk
    JOIN customer c ON tc.bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    f.bill_customer_sk,
    f.total_net_profit,
    f.total_return_amount,
    f.ca_city,
    CASE 
        WHEN f.total_net_profit > 1000 THEN 'High Value'
        WHEN f.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM
    final_summary f
ORDER BY
    f.total_net_profit DESC;
