
WITH New_Customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk
    FROM customer
    WHERE c_first_shipto_date_sk = (SELECT MIN(c_first_shipto_date_sk) FROM customer)
),
Sales_Data AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales, COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_sold_date_sk <= 10000)
    GROUP BY ws_item_sk
),
Returns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
Sales_With_Returns AS (
    SELECT sd.ws_item_sk, sd.total_sales, COALESCE(r.total_returns, 0) AS total_returns,
           (sd.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM Sales_Data sd
    LEFT JOIN Returns r ON sd.ws_item_sk = r.sr_item_sk
),
Customer_Info AS (
    SELECT ca.*, cd.*
    FROM customer_address ca
    INNER JOIN customer_demographics cd ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cd.cd_demo_sk)
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
Final_Report AS (
    SELECT ci.ca_city, ci.ca_state, COUNT(DISTINCT nc.c_customer_sk) AS customer_count,
           SUM(swr.net_sales) AS total_net_sales
    FROM Customer_Info ci
    LEFT JOIN New_Customers nc ON ci.ca_address_sk = nc.c_current_addr_sk
    LEFT JOIN Sales_With_Returns swr ON swr.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price >= 10 AND i_current_price <= 100)
    GROUP BY ci.ca_city, ci.ca_state
)
SELECT fr.ca_city, fr.ca_state, fr.customer_count, fr.total_net_sales,
       ROW_NUMBER() OVER (ORDER BY fr.total_net_sales DESC) AS sales_rank
FROM Final_Report fr
WHERE fr.total_net_sales IS NOT NULL
ORDER BY fr.total_net_sales DESC
LIMIT 10;
