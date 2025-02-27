
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, level + 1
    FROM customer_address ca
    JOIN AddressCTE a ON ca.ca_state = a.ca_state AND a.level < 10
),
CustomerCTE AS (
    SELECT cd_marital_status, COUNT(*) AS married_count
    FROM customer_demographics
    WHERE cd_marital_status = 'M'
    GROUP BY cd_marital_status
),
WebSalesCTE AS (
    SELECT ws_bill_customer_sk,  
           SUM(ws_net_paid) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ItemCTE AS (
    SELECT i_item_sk,
           i_current_price,
           CASE 
               WHEN i_current_price IS NULL THEN 0
               ELSE i_current_price * 1.1
           END AS adjusted_price
    FROM item
),
HighIncomeCustomers AS (
    SELECT DISTINCT c.c_customer_id, h.hd_income_band_sk
    FROM customer c
    JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    WHERE h.hd_income_band_sk IN (SELECT ib_income_band_sk 
                                   FROM income_band 
                                   WHERE ib_upper_bound > 100000)
),
AggregateReturns AS (
    SELECT sr_customer_sk,
           SUM(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount,
           COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
ComplexSubquery AS (
    SELECT ws.ws_ship_date_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN HighIncomeCustomers hic ON ws.ws_bill_customer_sk = hic.c_customer_id
    WHERE ws.ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_ship_date_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(c.married_count, 0) AS married_customers,
    ws.total_profit,
    dt.d_day_name,
    CASE
        WHEN ws.total_profit > 1000 THEN 'High Performer'
        WHEN ws.total_profit IS NULL THEN 'No Sales'
        ELSE 'Average Performer'
    END AS performance_category
FROM AddressCTE a
LEFT JOIN CustomerCTE c ON 1=1
LEFT JOIN ComplexSubquery ws ON ws.ws_ship_date_sk = a.ca_address_sk
JOIN date_dim dt ON dt.d_date_sk = ws.ws_ship_date_sk
WHERE a.level = 1
ORDER BY a.ca_city ASC, married_customers DESC NULLS LAST;
