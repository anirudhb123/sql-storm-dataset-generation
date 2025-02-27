
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
    WHERE ca_state IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.web_site_id
),
TopWebsites AS (
    SELECT web_site_id
    FROM SalesData
    WHERE rank <= 5
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        AVG(cr.return_amt) AS avg_return_amt
    FROM catalog_returns cr
    WHERE cr.return_quantity IS NOT NULL AND cr.refunded_cash IS NOT NULL
    GROUP BY cr.returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COALESCE(SUM(cr.total_returns), 0) AS total_returns,
        COALESCE(SUM(cr.avg_return_amt), 0) AS total_return_amt,
        (SELECT COUNT(*) FROM CustomerReturns) AS total_customers
    FROM CustomerReturns cr
    GROUP BY cr.returning_customer_sk
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    tw.web_site_id,
    sd.total_profit,
    sd.order_count,
    cr.total_returns,
    cr.total_return_amt,
    (cr.total_returns * 1.0 / NULLIF(sd.order_count, 0)) AS return_rate,
    (SELECT MAX(wh.w_warehouse_name) 
     FROM warehouse wh 
     WHERE wh.w_warehouse_sq_ft > (SELECT AVG(s.s_floor_space) FROM store s)) AS largest_warehouse_name
FROM AddressHierarchy ah
JOIN TopWebsites tw ON tw.web_site_id IN (SELECT DISTINCT ws.web_site_id FROM web_sales ws)
JOIN SalesData sd ON sd.web_site_id = tw.web_site_id
LEFT JOIN CombinedReturns cr ON cr.returning_customer_sk = sd.ws_bill_customer_sk
WHERE ah.city_rank = 1 AND sd.total_profit > 5000
ORDER BY return_rate DESC NULLS LAST;
