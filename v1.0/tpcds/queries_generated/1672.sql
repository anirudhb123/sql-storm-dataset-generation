
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
),
TopSales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales_price,
        AVG(sd.ws_net_profit) AS avg_profit
    FROM SalesData sd
    WHERE sd.rn <= 5
    GROUP BY sd.ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IS NOT NULL
    GROUP BY sr.sr_customer_sk
),
Summary AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.total_sales_price, 0) AS total_sales_price,
        COALESCE(ts.avg_profit, 0) AS avg_profit
    FROM customer cs
    LEFT JOIN CustomerReturns cr ON cs.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN TopSales ts ON cs.c_customer_sk = ts.ws_order_number
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_id) AS customer_count,
    AVG(s.total_quantity) AS avg_quantity,
    SUM(s.total_sales_price) AS total_sales,
    SUM(s.total_return_amt) AS returned_sales,
    SUM(CASE WHEN s.total_quantity > 0 THEN s.total_quantity ELSE NULL END) AS positive_sales
FROM Summary s
JOIN customer_address ca ON s.c_customer_sk = ca.ca_address_sk
WHERE s.total_sales_price > 0 OR s.total_return_amt > 0
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT s.c_customer_sk) > 10
ORDER BY total_sales DESC;
