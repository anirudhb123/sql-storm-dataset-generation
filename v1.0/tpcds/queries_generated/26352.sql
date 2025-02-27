
WITH concatenated_info AS (
  SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    CONCAT(DATE_FORMAT(d.d_date, '%Y-%m-%d'), ' ', LPAD(t.t_hour, 2, '0'), ':', LPAD(t.t_minute, 2, '0')) AS transaction_time,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count
  FROM 
    customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND d.d_year = 2023 
  GROUP BY 
    c.c_customer_id, full_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, transaction_time
)
SELECT 
  full_name,
  ca_city,
  ca_state,
  cd_gender,
  cd_marital_status,
  transaction_time,
  orders_count,
  CASE 
    WHEN orders_count > 5 THEN 'High Value'
    WHEN orders_count BETWEEN 1 AND 5 THEN 'Medium Value'
    ELSE 'Low Value'
  END AS customer_value_category
FROM 
  concatenated_info
ORDER BY 
  orders_count DESC;
