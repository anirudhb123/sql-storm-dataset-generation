
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number,
           ca_street_name, ca_city, ca_state, ca_zip
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, 
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name) AS street,
           ca.ca_city, ca.ca_state, ca.ca_zip
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.ca_city IS NOT NULL
), 
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_net_paid_inc_tax) AS max_payment,
        MIN(ws.ws_net_paid_inc_tax) AS min_payment,
        AVG(ws.ws_net_paid_inc_tax) AS avg_payment
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_marital_status = 'S' AND cd_gender = 'F'
    )
    GROUP BY ws.web_site_id
),
ReturnsData AS (
    SELECT ws.web_site_id,
           COUNT(wr_return_quantity) AS total_returns,
           SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    GROUP BY ws.web_site_id
),
BenchmarkData AS (
    SELECT sd.web_site_id,
           sd.total_profit,
           sd.total_orders,
           rd.total_returns,
           rd.total_return_value,
           CASE 
               WHEN sd.total_orders = 0 THEN 0
               ELSE (rd.total_return_value / sd.total_profit) * 100
           END AS return_rate_percentage
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.web_site_id = rd.web_site_id
)
SELECT 
    bh.ca_address_id AS "Address ID",
    bh.ca_city AS "City",
    bh.ca_state AS "State",
    b.web_site_id AS "Website ID",
    b.total_profit,
    b.total_orders,
    b.total_returns,
    b.total_return_value,
    b.return_rate_percentage,
    ROW_NUMBER() OVER (PARTITION BY bh.ca_state ORDER BY b.total_profit DESC) AS rank_in_state
FROM BenchmarkData b
JOIN AddressHierarchy bh ON bh.ca_zip IN (
    SELECT DISTINCT ca_zip 
    FROM customer_address 
    WHERE ca_zip IS NOT NULL
)
ORDER BY b.total_profit DESC
FETCH FIRST 10 ROWS ONLY;
