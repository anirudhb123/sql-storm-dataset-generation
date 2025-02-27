
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_order_number, 
           SUM(ws_sales_price) AS total_sales, 
           COUNT(ws_quantity) AS total_quantity,
           ws_item_sk
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk
    UNION ALL
    SELECT cr_order_number AS ws_order_number, 
           SUM(cr_return_amount) * -1 AS total_sales, 
           SUM(cr_return_quantity) * -1 AS total_quantity,
           cr_item_sk
    FROM catalog_returns
    GROUP BY cr_order_number, cr_item_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    SUM(CASE 
            WHEN ss.ws_sales_price IS NOT NULL THEN ss.total_sales 
            ELSE 0 
        END) AS total_sales,
    SUM(CASE 
            WHEN sr_ext.ext_sales_price IS NOT NULL THEN sr_ext.ext_sales_price 
            ELSE 0 
        END) AS total_returns,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(CASE 
            WHEN ss.total_quantity > 0 THEN ss.total_quantity 
            ELSE NULL 
        END) AS avg_quantity_per_order
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN Sales_CTE ss ON c.c_customer_sk = ss.ws_order_number
LEFT JOIN (
    SELECT wr_returning_customer_sk, 
           SUM(wr_return_amt) AS ext_sales_price 
    FROM web_returns 
    GROUP BY wr_returning_customer_sk
) sr_ext ON c.c_customer_sk = sr_ext.wr_returning_customer_sk
WHERE ca.ca_country = 'USA'
AND (ca.ca_state IN (SELECT cd.state FROM customer_demographics cd WHERE cd.cd_marital_status = 'M'))
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_sales DESC, total_customers DESC
LIMIT 10;
