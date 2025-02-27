
WITH RECURSIVE SalesRank AS (
    SELECT 
        cs_bill_customer_sk, 
        SUM(cs_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS sales_rank
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        sr.total_profit,
        sr.sales_rank
    FROM Customer c
    JOIN SalesRank sr ON c.c_customer_sk = sr.cs_bill_customer_sk
    WHERE sr.sales_rank <= 10
),
PopularItems AS (
    SELECT 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
    HAVING SUM(ws.ws_quantity) > 100
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(DISTINCT sr.returned_quantity), 0) AS total_returns
    FROM Customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    pi.i_item_id,
    pi.total_quantity_sold,
    cr.total_returns
FROM TopCustomers tc
JOIN PopularItems pi ON tc.sales_rank <= 5
JOIN CustomerReturns cr ON tc.c_customer_id = cr.c_customer_id
ORDER BY tc.total_profit DESC, pi.total_quantity_sold DESC
LIMIT 20;
