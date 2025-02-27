
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    
    UNION ALL
    
    SELECT ca.ca_address_sk, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.state = 'CA' AND ah.level < 3
),
demographics_with_income AS (
    SELECT cd.*, ib.ib_lower_bound, ib.ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd_credit_rating IN ('Good', 'Excellent')
),
sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
return_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_order_count
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    a.ca_street_name,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    s.ws_item_sk,
    ss.total_quantity,
    ss.total_net_paid,
    rs.total_returns,
    (COALESCE(ss.total_net_paid, 0) - COALESCE(rs.total_returns, 0)) AS net_sales,
    CASE 
        WHEN ss.total_net_paid IS NULL THEN 'No Sales'
        WHEN rs.total_returns > 0 THEN 'Returns Applied'
        ELSE 'Normal Sales' 
    END AS sales_status
FROM address_hierarchy a
JOIN demographics_with_income d ON a.ca_city = d.cd_demo_sk
JOIN sales_summary ss ON ss.ws_item_sk IN (
    SELECT cs_item_sk FROM catalog_sales cs
    WHERE cs_bill_cdemo_sk = d.cd_demo_sk
)
LEFT JOIN return_summary rs ON rs.wr_item_sk = ss.ws_item_sk
WHERE a.level = 2
ORDER BY a.ca_country, net_sales DESC
LIMIT 50;
