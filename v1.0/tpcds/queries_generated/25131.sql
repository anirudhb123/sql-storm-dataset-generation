
WITH AddressStats AS (
  SELECT 
    ca_state,
    COUNT(*) AS address_count,
    STRING_AGG(ca_city, '; ') AS cities,
    STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets
  FROM 
    customer_address
  GROUP BY 
    ca_state
),
CustomerStats AS (
  SELECT 
    cd_gender,
    COUNT(*) AS customer_count,
    STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names,
    SUM(cd_purchase_estimate) AS total_purchase_estimate
  FROM 
    customer c
  JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  GROUP BY 
    cd_gender
),
SalesData AS (
  SELECT 
    ws_bill_cdemo_sk AS demo_sk,
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(*) AS transactions
  FROM 
    web_sales
  GROUP BY 
    ws_bill_cdemo_sk
)
SELECT
  a.ca_state,
  a.address_count,
  a.cities,
  c.cd_gender,
  c.customer_count,
  c.customer_names,
  s.total_sales,
  s.transactions,
  s.total_sales / NULLIF(s.transactions, 0) AS avg_sales_per_transaction
FROM 
  AddressStats a
LEFT JOIN 
  CustomerStats c ON a.ca_state = 'NY'  -- Filter address by state for demonstration
LEFT JOIN 
  SalesData s ON c.customer_count > 100  -- Filter based on customer count for meaningful joins
WHERE 
  a.address_count > 50
ORDER BY 
  a.address_count DESC, 
  c.customer_count DESC;
