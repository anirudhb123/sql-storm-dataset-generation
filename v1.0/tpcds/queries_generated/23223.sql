
WITH RecursiveSales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                  FROM date_dim 
                                  WHERE d_year = 2023 
                                  AND d_month_seq IN (SELECT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_moy IN (1, 2, 6)))
    GROUP BY ws.ws_item_sk
), RankedCustomerDemographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS demo_rank
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate IS NOT NULL
), AddressDetails AS (
    SELECT ca.ca_address_sk,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ' ', COALESCE(ca.ca_suite_number, '')) AS full_address
    FROM customer_address ca
    WHERE ca.ca_country = 'USA'
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cd.cd_gender, 'U') AS gender, 
    total_quantity,
    total_revenue,
    full_address
FROM customer cs
LEFT JOIN RecursiveSales r ON cs.c_customer_sk = r.ws_item_sk
LEFT JOIN RankedCustomerDemographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk AND cd.demo_rank <= 10
LEFT JOIN AddressDetails a ON cs.c_current_addr_sk = a.ca_address_sk
WHERE (r.total_revenue > (SELECT AVG(total_revenue) FROM RecursiveSales) OR r.total_quantity IS NULL)
AND EXISTS (SELECT 1 FROM store s WHERE s.s_county IS NULL AND s.s_state = 'CA')
ORDER BY total_revenue DESC NULLS LAST
LIMIT 100
UNION ALL
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(cdmale.cd_gender, 'U') AS gender,
    0 AS total_quantity,
    0 AS total_revenue,
    NULL AS full_address
FROM customer cu
LEFT JOIN RankedCustomerDemographics cdmale ON cu.c_current_cdemo_sk = cdmale.cd_demo_sk
WHERE cdmale.cd_gender = 'M' AND NOT EXISTS (SELECT 1 FROM RecursiveSales r WHERE r.ws_item_sk = cu.c_customer_sk)
ORDER BY total_revenue DESC NULLS LAST;
