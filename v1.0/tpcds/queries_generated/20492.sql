
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY ws.ws_item_sk
),
TopItem AS (
    SELECT 
        item_desc, 
        total_quantity, 
        total_net_paid 
    FROM RankedSales 
    JOIN item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE sales_rank <= 5
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent_per_order
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    cs.c_customer_id,
    cs.orders_count,
    cs.total_spent,
    cs.avg_spent_per_order,
    ti.item_desc,
    ti.total_quantity,
    ti.total_net_paid,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    COALESCE(ti.total_net_paid, 0) AS item_net_paid,
    (SELECT COUNT(DISTINCT r.r_reason_sk) FROM store_returns r WHERE r.sr_customer_sk = c.c_customer_sk) AS return_count
FROM CustomerSummary cs
LEFT JOIN TopItem ti ON cs.orders_count > 0 
ORDER BY cs.total_spent DESC, ti.total_net_paid DESC
LIMIT 100;
