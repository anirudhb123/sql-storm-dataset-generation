
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date, d_year FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
    UNION ALL
    SELECT d_date_sk + 1, d_date, d_year
    FROM DateRange
    WHERE d_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_paid) AS total_spent,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY c.c_customer_sk
),
ItemReturns AS (
    SELECT 
        ir.ir_item_sk,
        COUNT(ir.ir_return_quantity) AS total_returns,
        SUM(ir.ir_return_amt) AS total_return_amount
    FROM (
        SELECT cr_item_sk AS ir_item_sk, cr_return_quantity, cr_return_amount AS ir_return_amt
        FROM catalog_returns
        UNION ALL
        SELECT wr_item_sk AS ir_item_sk, wr_return_quantity, wr_return_amt AS ir_return_amt
        FROM web_returns
    ) ir
    GROUP BY ir.ir_item_sk
)
SELECT 
    da.d_year,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    SUM(cs.total_spent) AS total_revenue,
    MAX(cs.total_spent) AS max_spent_per_customer,
    COUNT(DISTINCT ir.ir_item_sk) AS total_items_returned,
    SUM(ir.total_return_amount) AS total_return_revenue
FROM DateRange da 
LEFT JOIN CustomerStats cs ON cs.total_purchases > 0
LEFT JOIN ItemReturns ir ON ir.total_returns > 0
WHERE 
    da.d_year IS NOT NULL 
    AND COALESCE(cs.total_spent, 0) > (SELECT AVG(total_spent) FROM CustomerStats)
GROUP BY da.d_year
ORDER BY da.d_year DESC
LIMIT 10;
