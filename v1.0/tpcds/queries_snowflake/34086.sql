
WITH RECURSIVE RankedReturns AS (
    SELECT wr_returned_date_sk, wr_item_sk, wr_return_quantity, wr_return_amt
    FROM web_returns
    WHERE wr_returned_date_sk IS NOT NULL
    UNION ALL
    SELECT wr_returned_date_sk, wr_item_sk, wr_return_quantity + 1, wr_return_amt + 5
    FROM RankedReturns
    WHERE wr_return_quantity < 10
),
SalesSummary AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerSpend AS (
    SELECT
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count,
        c.c_birth_month,
        CASE
            WHEN SUM(ws_ext_sales_price) > 1000 THEN 'High'
            WHEN SUM(ws_ext_sales_price) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_birth_month
)
SELECT 
    CONCAT(CAST(c.c_first_name AS STRING), ' ', CAST(c.c_last_name AS STRING)) AS customer_name,
    cs.total_spent,
    cs.order_count,
    ss.total_sales_price,
    ss.avg_sales_price,
    COALESCE(RR.wr_return_quantity, 0) AS return_quantity,
    COALESCE(RR.wr_return_amt, 0.00) AS return_amount
FROM CustomerSpend cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN SalesSummary ss ON ss.ws_item_sk = (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_bill_customer_sk = c.c_customer_sk
    ORDER BY ws_ext_sales_price DESC
    LIMIT 1
)
LEFT JOIN RankedReturns RR ON RR.wr_item_sk = ss.ws_item_sk
WHERE cs.order_count > 5
AND cs.spending_category = 'High'
ORDER BY cs.total_spent DESC, return_quantity DESC;
