
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS total_returns,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_amount,
        cr.total_returns
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.return_rank <= 10 -- Keep top 10 returning customers
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
ProfitAnalysis AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.total_net_profit) AS item_net_profit,
        AVG(sd.total_quantity_sold) AS avg_quantity_sold
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    pa.item_net_profit,
    pa.avg_quantity_sold,
    CASE 
       WHEN pa.item_net_profit IS NULL THEN 'No Sales' 
       ELSE 'Sales Exist' 
    END AS sales_status
FROM TopCustomers tc
LEFT JOIN ProfitAnalysis pa ON tc.sr_customer_sk = pa.ws_item_sk
WHERE tc.total_return_amount > 1000
ORDER BY tc.total_return_amount DESC, pa.item_net_profit DESC;
