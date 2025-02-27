
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS total_return_orders,
        SUM(cr_return_amt) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_sales_quantity,
        SUM(ws_sales_price) AS total_web_sales_amount,
        AVG(ws_net_profit) AS avg_web_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
StoreSales AS (
    SELECT
        ss_customer_sk,
        SUM(ss_quantity) AS total_store_sales_quantity,
        SUM(ss_net_paid) AS total_store_sales_amount
    FROM store_sales
    GROUP BY ss_customer_sk
)
SELECT
    COALESCE(w.customer_sk, s.customer_sk) AS customer_sk,
    COALESCE(w.total_web_sales_quantity, 0) AS web_sales_quantity,
    COALESCE(w.total_web_sales_amount, 0) AS web_sales_amount,
    COALESCE(s.total_store_sales_quantity, 0) AS store_sales_quantity,
    COALESCE(s.total_store_sales_amount, 0) AS store_sales_amount,
    COALESCE(c.total_returned_quantity, 0) AS total_return_qty,
    COALESCE(c.total_return_orders, 0) AS total_return_orders,
    CASE 
        WHEN COALESCE(s.total_store_sales_amount, 0) = 0 THEN 0
        ELSE ROUND((COALESCE(w.total_web_sales_amount, 0) / COALESCE(s.total_store_sales_amount, 0)) * 100, 2)
    END AS web_to_store_ratio,
    CASE 
        WHEN c.total_return_qty IS NULL THEN 'No Returns'
        WHEN c.total_return_qty > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM
    (SELECT DISTINCT cr_returning_customer_sk AS customer_sk FROM catalog_returns) AS returns_customers
FULL OUTER JOIN WebSales w ON returns_customers.customer_sk = w.ws_bill_customer_sk
FULL OUTER JOIN StoreSales s ON returns_customers.customer_sk = s.ss_customer_sk
LEFT JOIN CustomerReturns c ON c.cr_returning_customer_sk = COALESCE(w.ws_bill_customer_sk, s.ss_customer_sk)
WHERE
    (COALESCE(w.total_web_sales_quantity, 0) > 0 OR COALESCE(s.total_store_sales_quantity, 0) > 0)
    AND (w.total_web_sales_amount IS NOT NULL OR s.total_store_sales_amount IS NOT NULL)
ORDER BY return_status, web_sales_amount DESC
LIMIT 100;
