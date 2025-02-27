
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 90
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit
    FROM RankedSales cs
    JOIN customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    WHERE cs.profit_rank <= 5
),
RecentReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY sr_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN COALESCE(rr.total_return_amount, 0) > (tc.total_profit * 0.1) THEN 'High Return'
        WHEN COALESCE(rr.total_return_amount, 0) = 0 THEN 'No Returns'
        ELSE 'Moderate Return'
    END AS return_category
FROM TopCustomers tc
LEFT JOIN RecentReturns rr ON rr.sr_customer_sk = tc.c_customer_id
ORDER BY tc.total_profit DESC, tc.c_last_name, tc.c_first_name;
