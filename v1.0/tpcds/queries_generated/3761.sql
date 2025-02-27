
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returns > 0
),
HighValueItems AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450200  -- Example date range
    GROUP BY ws_item_sk
    HAVING SUM(ws_ext_sales_price) > 1000
),
ProfitableItems AS (
    SELECT 
        i.i_item_id,
        (SUM(ws_ext_sales_price) - SUM(ws_ext_wholesale_cost)) AS net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY i.i_item_id
    HAVING (SUM(ws_ext_sales_price) - SUM(ws_ext_wholesale_cost)) > 500
),
CustomerSummaries AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_return_amount,
    tc.avg_return_quantity,
    cs.total_orders,
    cs.total_net_profit,
    hi.total_sales AS high_value_item_sales,
    pi.net_profit AS profitable_item_sales
FROM TopCustomers tc
LEFT JOIN CustomerSummaries cs ON tc.c_customer_id = cs.c_customer_id
LEFT JOIN HighValueItems hi ON hi.ws_item_sk IN (SELECT cs_qws_item_sk FROM web_sales WHERE ws_bill_customer_sk = tc.sr_customer_sk)
LEFT JOIN ProfitableItems pi ON pi.i_item_id IN (SELECT cs_ws_item_id FROM web_sales WHERE ws_bill_customer_sk = tc.sr_customer_sk)
WHERE tc.rank <= 10
ORDER BY tc.total_return_amount DESC, cs.total_net_profit DESC;
