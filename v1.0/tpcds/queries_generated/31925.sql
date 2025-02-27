
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    GROUP BY s_store_sk, ss_sold_date_sk
    HAVING SUM(ss_net_profit) > 1000
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM customer AS c
    LEFT JOIN CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cr.return_count, cr.total_returned_amount
    HAVING SUM(ws.ws_net_profit) > 5000
),
FinalReport AS (
    SELECT 
        hv.c_customer_sk, 
        hv.c_first_name,
        hv.c_last_name,
        hv.total_sales_profit,
        hv.return_count,
        hv.total_returned_amount,
        sh.total_profit AS store_profit
    FROM HighValueCustomers AS hv
    LEFT JOIN SalesHierarchy AS sh ON hv.c_customer_sk = sh.s_store_sk
    WHERE sh.rank <= 10
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales_profit,
    f.return_count,
    f.total_returned_amount,
    f.store_profit,
    CASE 
        WHEN f.total_sales_profit > 20000 THEN 'VIP'
        WHEN f.total_sales_profit > 15000 THEN 'Premium'
        ELSE 'Regular'
    END AS customer_tier
FROM FinalReport AS f
ORDER BY f.total_sales_profit DESC;
