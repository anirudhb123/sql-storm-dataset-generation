
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                             AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
AggregateData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS average_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerActivity AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS average_spent
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        ca.total_orders,
        ca.total_spent,
        RANK() OVER (ORDER BY ca.total_spent DESC) AS rank
    FROM 
        CustomerActivity ca
    JOIN customer c ON ca.c_customer_id = c.c_customer_id
    WHERE 
        ca.total_orders > 0
),
ReturnsData AS (
    SELECT 
        sr.returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk, sr_item_sk
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    ad.total_quantity,
    ad.total_profit,
    tc.total_orders,
    tc.total_spent,
    rd.total_returns,
    'High Value' AS customer_segment
FROM 
    item it
LEFT JOIN 
    AggregateData ad ON it.i_item_sk = ad.ws_item_sk
LEFT JOIN 
    TopCustomers tc ON tc.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c 
        ORDER BY c.c_customer_sk 
        LIMIT 1
    )
LEFT JOIN 
    ReturnsData rd ON it.i_item_sk = rd.sr_item_sk
WHERE 
    ad.total_profit > 1000
    AND (rd.total_returns IS NULL OR rd.total_returns < 5)
ORDER BY 
    ad.total_profit DESC;
