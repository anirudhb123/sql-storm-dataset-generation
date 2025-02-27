
WITH CustomerData AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           hd.hd_income_band_sk,
           hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
SalesData AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
CombinedData AS (
    SELECT cd.c_customer_sk, 
           cd.c_first_name, 
           cd.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           hd.hd_income_band_sk, 
           hd.hd_buy_potential, 
           sd.total_sales, 
           sd.total_orders
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
), 
SummaryStats AS (
    SELECT hd_income_band_sk,
           COUNT(c_customer_sk) AS customer_count,
           AVG(total_sales) AS avg_sales,
           SUM(total_orders) AS total_orders
    FROM CombinedData
    GROUP BY hd_income_band_sk
)
SELECT ib.ib_income_band_sk, 
       ib.ib_lower_bound, 
       ib.ib_upper_bound, 
       ss.customer_count, 
       ss.avg_sales, 
       ss.total_orders
FROM SummaryStats ss
JOIN income_band ib ON ss.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY ib.ib_income_band_sk;
