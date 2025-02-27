
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS num_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS num_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450300
    GROUP BY ws_bill_customer_sk
),
StoreSalesSummary AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS num_orders
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450300
    GROUP BY ss_customer_sk
),
CombinedSales AS (
    SELECT
        COALESCE(w.ws_bill_customer_sk, s.ss_customer_sk) AS customer_sk,
        COALESCE(w.total_net_profit, 0) AS web_net_profit,
        COALESCE(s.total_net_profit, 0) AS store_net_profit,
        (COALESCE(w.total_net_profit, 0) + COALESCE(s.total_net_profit, 0)) AS combined_net_profit
    FROM WebSalesSummary w
    FULL OUTER JOIN StoreSalesSummary s ON w.ws_bill_customer_sk = s.ss_customer_sk
),
FinalSummary AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned_quantity, 0) AS total_returns,
        cs.combined_net_profit,
        CASE 
            WHEN cs.combined_net_profit >= 1000 THEN 'High Value'
            WHEN cs.combined_net_profit BETWEEN 500 AND 999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN CombinedSales cs ON c.c_customer_sk = cs.customer_sk
)
SELECT
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_returns,
    f.combined_net_profit,
    f.customer_value_category
FROM FinalSummary f
WHERE f.combined_net_profit IS NOT NULL
ORDER BY f.combined_net_profit DESC, f.total_returns DESC
LIMIT 100;
