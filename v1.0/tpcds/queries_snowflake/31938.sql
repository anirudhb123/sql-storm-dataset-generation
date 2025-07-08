
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
OrderStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
AvgReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
FilteredCustomers AS (
    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        cs.total_quantity, 
        cs.total_profit, 
        ar.return_count,
        ar.total_return_amount
    FROM CustomerHierarchy ch
    LEFT JOIN OrderStats cs ON ch.c_customer_sk = cs.ws_bill_customer_sk AND cs.rn = 1
    LEFT JOIN AvgReturns ar ON ch.c_customer_sk = ar.sr_customer_sk
)
SELECT 
    fc.c_customer_sk, 
    fc.c_first_name, 
    fc.c_last_name, 
    COALESCE(fc.total_quantity, 0) AS total_purchases,
    COALESCE(fc.total_profit, 0) AS total_profit,
    COALESCE(fc.return_count, 0) AS return_count,
    COALESCE(fc.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN fc.total_profit IS NULL OR fc.total_profit = 0 THEN 'No Purchases'
        WHEN fc.total_profit > 0 AND fc.total_profit <= 100 THEN 'Low Profit'
        WHEN fc.total_profit > 100 AND fc.total_profit <= 500 THEN 'Medium Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM FilteredCustomers fc
WHERE fc.c_customer_sk IS NOT NULL
ORDER BY fc.total_profit DESC, fc.c_customer_sk
LIMIT 100;
