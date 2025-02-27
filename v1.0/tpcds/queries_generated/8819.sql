
WITH item_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws_item_sk
), 
customer_info AS (
    SELECT 
        c_customer_sk, 
        cd_gender, 
        cd_marital_status, 
        ib_income_band_sk
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN income_band ON hd_income_band_sk = ib_income_band_sk
), 
sales_with_customer AS (
    SELECT 
        w.ws_item_sk, 
        ci.c_customer_sk, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.ib_income_band_sk,
        is.total_quantity_sold,
        is.total_sales
    FROM item_sales is
    JOIN web_sales w ON is.ws_item_sk = w.ws_item_sk
    JOIN customer_info ci ON w.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    ib_income_band_sk,
    COUNT(DISTINCT c_customer_sk) AS number_of_customers,
    AVG(total_quantity_sold) AS avg_quantity_sold,
    SUM(total_sales) AS total_sales_amount
FROM sales_with_customer
GROUP BY cd_gender, cd_marital_status, ib_income_band_sk
ORDER BY total_sales_amount DESC
LIMIT 10;
