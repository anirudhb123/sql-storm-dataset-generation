
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr.sr_customer_sk, 
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_returns
    FROM 
        store_returns sr 
    GROUP BY 
        sr.sr_customer_sk
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        cs.total_profit,
        cs.order_count,
        rs.return_count,
        rs.total_returns,
        CASE 
            WHEN cs.order_count = 0 THEN 'No Orders'
            WHEN rs.return_count IS NULL THEN 'No Returns'
            ELSE 'Active Customer'
        END AS customer_status,
        CASE 
            WHEN cs.avg_spent > 100 THEN 'High Value'
            WHEN cs.avg_spent BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary cs ON ci.c_customer_sk = cs.ws_bill_customer_sk
    LEFT JOIN 
        returns_summary rs ON ci.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_status ORDER BY total_profit DESC NULLS LAST) AS rn,
    LEAD(avg_spent, 1, 0) OVER (ORDER BY total_profit DESC NULLS LAST) AS next_avg_spent
FROM 
    final_report
WHERE 
    customer_status <> 'No Orders' AND
    (total_profit > 0 OR return_count > 0)
ORDER BY 
    customer_status, total_profit DESC;
