
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cs.c_customer_id,
        cs.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit IS NOT NULL
)
SELECT
    t.customer_id,
    t.total_net_profit,
    COALESCE(r.r_reason_desc, 'No Returns') AS return_reason,
    w.w_warehouse_name,
    DENSE_RANK() OVER (PARTITION BY COALESCE(return_reason, 'No Returns') ORDER BY t.total_net_profit DESC) AS rank_within_reason
FROM
    TopCustomers t
LEFT JOIN store_returns sr ON t.c_customer_id = sr.sr_customer_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN warehouse w ON sr.sr_store_sk = w.w_warehouse_sk
WHERE
    t.rank <= 10 AND t.total_net_profit > 1000
ORDER BY
    return_reason, t.total_net_profit DESC;
