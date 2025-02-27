
WITH RECURSIVE ItemReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY SUM(wr_return_quantity) DESC) AS rank
    FROM web_returns
    GROUP BY wr_item_sk
    HAVING SUM(wr_return_quantity) IS NOT NULL
),
TopReturns AS (
    SELECT 
        irs.wr_item_sk,
        irs.total_returns,
        irs.return_count,
        irs.total_return_amt,
        CASE 
            WHEN irs.total_returns > 100 THEN 'High Return'
            WHEN irs.total_returns BETWEEN 50 AND 100 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_category
    FROM ItemReturnStats irs
    WHERE irs.rank <= 10
),
CustomerPromoStats AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
PromotionalImpact AS (
    SELECT 
        tp.return_category,
        COUNT(DISTINCT cps.c_customer_id) AS unique_customers,
        SUM(cps.total_spent) AS total_spending
    FROM TopReturns tp
    JOIN CustomerPromoStats cps ON tp.wr_item_sk = cps.c_customer_id
    GROUP BY tp.return_category
)
SELECT 
    pi.return_category,
    pi.unique_customers,
    pi.total_spending,
    COALESCE(NULLIF(pi.total_spending / NULLIF(pi.unique_customers, 0), 0), 0) AS avg_spending_per_customer
FROM PromotionalImpact pi
FULL OUTER JOIN (
    SELECT 
        return_category,
        COUNT(*) AS customer_count
    FROM TopReturns
    GROUP BY return_category
) rc ON pi.return_category = rc.return_category
WHERE pi.total_spending IS NOT NULL OR rc.customer_count IS NOT NULL
ORDER BY pi.return_category ASC;
