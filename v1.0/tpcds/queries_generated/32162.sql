
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_last_name, c.c_first_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023 AND d.d_moy = 1 LIMIT 1)
    GROUP BY c.c_customer_sk, c.c_last_name, c.c_first_name
    
    UNION ALL

    SELECT sh.c_customer_sk, sh.c_last_name, sh.c_first_name, 
           (sh.total_sales * 1.1) AS total_sales
    FROM SalesHierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_current_cdemo_sk
)

SELECT DISTINCT c.c_first_name, c.c_last_name, sh.total_sales,
       CASE WHEN sh.total_sales IS NULL THEN 'No Sales' ELSE 'Sales Present' END AS sale_status
FROM customer c
LEFT JOIN SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
WHERE sh.total_sales >= COALESCE((SELECT AVG(total_sales) FROM SalesHierarchy), 0)
AND c.c_birth_year BETWEEN 1970 AND 2000
AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_country IS NULL)
ORDER BY sh.total_sales DESC
LIMIT 100;

SELECT ib.ib_lower_bound, ib.ib_upper_bound, 
       SUM(CASE WHEN ws.ws_ext_sales_price > 100.00 THEN ws.ws_quantity ELSE 0 END) AS high_value_sales
FROM income_band ib
JOIN web_sales ws ON (
    CASE
        WHEN ws.ws_net_paid BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 1
        ELSE 0
    END
) = 1
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
HAVING high_value_sales > 50;

SELECT ca.ca_city,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city
HAVING total_net_profit > (SELECT AVG(total_net_profit) 
                            FROM (SELECT SUM(ws.ws_net_profit) AS total_net_profit
                                  FROM web_sales ws
                                  GROUP BY ws.ws_ship_addr_sk) AS avg_profit)
ORDER BY total_orders DESC;
