
WITH 
  AddressAnalysis AS (
    SELECT 
      DISTINCT ca_city, 
      ca_state, 
      COUNT(*) AS address_count, 
      STRING_AGG(ca_street_name || ' ' || ca_street_type, ', ') AS full_address_list
    FROM 
      customer_address
    GROUP BY 
      ca_city, ca_state
  ),
  DemographicAnalysis AS (
    SELECT 
      cd_gender, 
      cd_marital_status, 
      COUNT(c.c_customer_sk) AS num_customers,
      SUM(cd_purchase_estimate) AS total_purchase_estimate, 
      STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names
    FROM 
      customer c
    JOIN 
      customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
      cd_gender, cd_marital_status
  ),
  SalesData AS (
    SELECT 
      ws.ws_order_number,
      SUM(ws.ws_quantity) AS total_quantity,
      SUM(ws.ws_net_profit) AS total_profit
    FROM 
      web_sales ws
    GROUP BY 
      ws.ws_order_number
  )
SELECT 
  A.ca_city, 
  A.ca_state, 
  A.address_count, 
  A.full_address_list, 
  D.cd_gender, 
  D.cd_marital_status, 
  D.num_customers, 
  D.total_purchase_estimate, 
  D.customer_names,
  S.total_quantity,
  S.total_profit
FROM 
  AddressAnalysis A
JOIN 
  DemographicAnalysis D ON D.num_customers > 10
JOIN 
  SalesData S ON S.total_quantity > 100
ORDER BY 
  A.ca_state, A.ca_city, D.cd_gender;
