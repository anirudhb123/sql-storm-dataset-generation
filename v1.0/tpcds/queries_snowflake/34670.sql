
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_street_name, ca_street_type, 0 AS Level
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ca.ca_street_name, ca.ca_street_type, a.Level + 1
    FROM customer_address ca
    JOIN AddressCTE a ON ca.ca_city = a.ca_city AND ca.ca_state = a.ca_state
    WHERE a.Level < 2
),
CustomerRanked AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender,
           COUNT(*) OVER (PARTITION BY cd.cd_gender) AS gender_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedSales AS (
    SELECT cs_bill_customer_sk, SUM(cs_net_profit) AS total_profit, COUNT(cs_order_number) AS total_orders
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_sk, cs.total_profit, cs.total_orders,
           DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM customer c
    JOIN AggregatedSales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cs.total_orders > 5
)
SELECT a.ca_city, a.ca_state, a.ca_street_name, a.ca_street_type,
       c.c_first_name, c.c_last_name, c.cd_gender, c.cd_marital_status,
       tc.total_profit, tc.total_orders, tc.profit_rank
FROM AddressCTE a
JOIN CustomerRanked c ON a.ca_city = c.c_first_name
JOIN TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = (SELECT MIN(sm_ship_mode_sk) FROM ship_mode) + 1  
WHERE tc.total_profit > 1000 AND c.rank_gender = 1
ORDER BY a.ca_state, tc.total_profit DESC;
