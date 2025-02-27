
WITH RECURSIVE IncomeDetails AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_buy_potential, hd_dep_count, hd_vehicle_count
    FROM household_demographics
    WHERE hd_buy_potential IS NOT NULL
      AND hd_dep_count > 0

    UNION ALL

    SELECT h.hd_demo_sk, h.hd_income_band_sk, h.hd_buy_potential, h.hd_dep_count, h.hd_vehicle_count
    FROM household_demographics h
    INNER JOIN IncomeDetails id ON h.hd_income_band_sk = id.hd_income_band_sk
    WHERE h.hd_dep_count > id.hd_dep_count
),
AvgIncome AS (
    SELECT ib_income_band_sk,
           AVG(hd_dep_count) AS avg_dep_count,
           AVG(hd_vehicle_count) AS avg_vehicle_count
    FROM IncomeDetails
    JOIN income_band ON IncomeDetails.hd_income_band_sk = income_band.ib_income_band_sk
    GROUP BY ib_income_band_sk
),
SalesData AS (
    SELECT ss_item_sk,
           SUM(ss_quantity) AS total_quantity,
           SUM(ss_net_paid_inc_tax) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
      AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss_item_sk
),
CustomerAggregate AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
           SUM(ss.ss_net_paid_inc_tax) AS total_spent,
           AVG(ss.ss_sales_price) AS avg_item_price
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT ca.ca_city,
       COUNT(DISTINCT ca.ca_address_sk) AS address_count,
       COALESCE(SUM(s.total_quantity), 0) AS total_items_sold,
       COALESCE(SUM(s.total_sales), 0) AS total_income_generated,
       AVG(i.avg_dep_count) AS avg_dep_per_income_band,
       SUM(CASE WHEN c.total_spent IS NULL THEN 0 ELSE c.total_spent END) AS total_sales_value,
       RANK() OVER (ORDER BY SUM(s.total_sales) DESC) AS sales_rank
FROM customer_address ca
LEFT JOIN SalesData s ON s.ss_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 20)
LEFT JOIN AvgIncome i ON i.ib_income_band_sk = (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk = c.c_current_hdemo_sk)
LEFT JOIN CustomerAggregate c ON c.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT ca.ca_address_sk) > 10
ORDER BY sales_rank;
