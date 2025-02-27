
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_email_address,
           ca_state, 
           cd_income_band_sk, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY c_customer_sk) AS rn
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
), 
SalesCTE AS (
    SELECT ws_ship_date_sk, ws_item_sk, ws_order_number, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk, ws_order_number
),
MaxSales AS (
    SELECT MAX(total_sales) AS max_sales
    FROM SalesCTE
)

SELECT cte.c_first_name, cte.c_last_name, cte.c_email_address, cte.ca_state,
       CASE WHEN cte.cd_income_band_sk IS NOT NULL THEN 'Income Band Exists' 
            ELSE 'No Income Band' END AS income_band_status,
       COALESCE(s.total_sales, 0) AS total_sales,
       s.order_count,
       CASE 
           WHEN m.max_sales IS NOT NULL THEN (s.total_sales / m.max_sales) * 100
           ELSE 0 
           END AS sales_percentage_of_max
FROM CustomerCTE cte
LEFT JOIN SalesCTE s ON cte.c_customer_sk = s.ws_order_number
CROSS JOIN MaxSales m
WHERE cte.rn <= 10
ORDER BY cte.ca_state, s.order_count DESC;
