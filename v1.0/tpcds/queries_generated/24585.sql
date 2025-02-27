
WITH CustomerReturns AS (
    SELECT 
        C.c_customer_id,
        COALESCE(SR.sr_return_quantity, 0) AS total_return_quantity,
        COALESCE(SR.sr_return_amt, 0) AS total_return_amount,
        COALESCE(WR.wr_return_quantity, 0) AS web_return_quantity,
        COALESCE(WR.wr_return_amt, 0) AS web_return_amount
    FROM customer C
    LEFT JOIN store_returns SR ON C.c_customer_sk = SR.sr_customer_sk
    LEFT JOIN web_returns WR ON C.c_customer_sk = WR.wr_returning_customer_sk
    GROUP BY C.c_customer_id
),
SalesData AS (
    SELECT 
        WS.ws_ship_customer_sk,
        SUM(WS.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT WS.ws_order_number) AS total_orders,
        AVG(WS.ws_sales_price) AS avg_sales_price,
        SUM(WS.ws_net_profit) AS total_net_profit
    FROM web_sales WS 
    GROUP BY WS.ws_ship_customer_sk
),
CombinedData AS (
    SELECT 
        CR.c_customer_id,
        COALESCE(SD.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(SD.total_orders, 0) AS total_orders,
        COALESCE(SD.avg_sales_price, 0) AS avg_sales_price,
        CR.total_return_quantity,
        CR.total_return_amount,
        CR.web_return_quantity,
        CR.web_return_amount,
        (CR.total_return_amount - CR.web_return_amount) AS store_return_difference
    FROM CustomerReturns CR
    LEFT JOIN SalesData SD ON CR.c_customer_id = (SELECT C.c_customer_id FROM customer C WHERE C.c_customer_sk = SD.ws_ship_customer_sk)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CD.total_quantity_sold,
    CD.total_orders,
    CD.avg_sales_price,
    CD.total_return_quantity,
    CD.total_return_amount,
    CASE 
        WHEN CD.store_return_difference > 0 THEN 'Higher Store Returns'
        WHEN CD.store_return_difference < 0 THEN 'Higher Web Returns'
        ELSE 'Equal Returns'
    END AS return_status,
    P.p_promo_name,
    P.p_discount_active
FROM CombinedData CD
JOIN customer C ON CD.c_customer_id = C.c_customer_id
LEFT JOIN promotion P ON C.c_customer_id % 2 = P.p_promo_sk % 2
WHERE (CD.total_quantity_sold > (SELECT AVG(total_quantity_sold) FROM SalesData) OR 
       CD.total_return_quantity > (SELECT AVG(total_return_quantity) FROM CustomerReturns))
ORDER BY CD.total_net_profit DESC 
LIMIT 10;
