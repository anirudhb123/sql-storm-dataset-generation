
WITH customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           cd.cd_credit_rating 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
demographics_summary AS (
    SELECT h.hd_income_band_sk, 
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           COUNT(DISTINCT ci.c_customer_sk) AS customer_count
    FROM household_demographics h
    LEFT JOIN customer_info ci ON ci.c_customer_sk = h.hd_demo_sk
    LEFT JOIN customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
    GROUP BY h.hd_income_band_sk
)
SELECT ci.c_first_name, 
       ci.c_last_name, 
       ci.cd_gender, 
       ss.total_sales, 
       ss.total_orders, 
       ss.total_quantity, 
       ds.avg_purchase_estimate, 
       ds.customer_count
FROM sales_summary ss
JOIN customer_info ci ON ss.ws_bill_customer_sk = ci.c_customer_sk
JOIN demographics_summary ds ON ci.c_current_cdemo_sk = ds.hd_demo_sk
WHERE ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY ss.total_sales DESC
LIMIT 50;
