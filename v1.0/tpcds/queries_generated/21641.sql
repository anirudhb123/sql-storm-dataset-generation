
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_customer_sk
), CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), HighSpenders AS (
    SELECT 
        s.ws_customer_sk,
        s.total_sales
    FROM SalesCTE s 
    WHERE s.rank <= 5
), ShippingStats AS (
    SELECT 
        sm_type,
        SUM(CASE WHEN ws_ext_sales_price IS NOT NULL THEN 1 ELSE 0 END) AS total_shipments,
        SUM(ws_ext_sales_price) AS total_shipped_value
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm_type
), ComplexAnalysis AS (
    SELECT
        cd.c_customer_id,
        cd.ca_city,
        cd.ca_state,
        hs.total_sales,
        ss.total_shipped_value,
        CASE 
            WHEN hs.total_sales > 10000 THEN 'High Value'
            WHEN hs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_val_category
    FROM CustomerDetails cd
    JOIN HighSpenders hs ON cd.c_current_cdemo_sk = hs.ws_customer_sk
    LEFT JOIN ShippingStats ss ON cd.ca_city = ss.sm_type
)
SELECT 
    ca.ca_city AS city,
    ca.ca_state AS state,
    MAX(ca.purchase_estimate) AS max_purchase_estimate,
    MIN(ca.total_sales) AS min_sales,
    AVG(ca.dependents) AS avg_dependents
FROM ComplexAnalysis ca
GROUP BY ca.ca_city, ca.ca_state
HAVING MAX(ca.purchase_estimate) > (SELECT AVG(purchase_estimate) FROM CustomerDetails WHERE purchase_estimate IS NOT NULL)
ORDER BY 1, 2 DESC
LIMIT 10 OFFSET 5;
