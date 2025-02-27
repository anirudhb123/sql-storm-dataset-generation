
WITH RECURSIVE demographic_income AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        hd_income_band_sk,
        1 AS level
    FROM 
        customer_demographics 
    LEFT JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
    WHERE 
        cd_purchase_estimate IS NOT NULL

    UNION ALL

    SELECT 
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd2.hd_income_band_sk,
        level + 1
    FROM 
        customer c
    JOIN 
        demographic_income ON c.c_current_cdemo_sk = demographic_income.cd_demo_sk
    JOIN 
        household_demographics hd2 ON c.c_current_hdemo_sk = hd2.hd_demo_sk
    WHERE 
        level < 3
)

SELECT 
    d.ca_city,
    COUNT(DISTINCT d.ca_address_id) AS distinct_addresses,
    STRING_AGG(DISTINCT CONCAT(cp.cp_catalog_page_id, ': ', cp.cp_description) ORDER BY cp.cp_catalog_page_id) AS catalog_info,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
    AVG(COALESCE(ib.ib_lower_bound, 0.00)) AS avg_income_lower_bound,
    MAX(sm.sm_carrier) FILTER (WHERE d.d_holiday = 'Y') AS max_carrier_on_holidays
FROM 
    customer_address d
LEFT JOIN 
    (SELECT 
         DISTINCT cd_demo_sk, 
         MAX(cd_purchase_estimate) OVER (PARTITION BY cd_demo_sk) AS max_purchase
     FROM 
         demographic_income) dem ON d.ca_address_sk = dem.cd_demo_sk
LEFT JOIN 
    catalog_page cp ON dem.cd_demo_sk = cp.cp_catalog_page_sk
JOIN 
    income_band ib ON dem.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk 
                                            FROM store_sales 
                                            WHERE ss_item_sk = (SELECT ss_item_sk 
                                                                FROM web_sales 
                                                                WHERE ws_bill_customer_sk = d.ca_address_sk
                                                                LIMIT 1) LIMIT 1)
WHERE 
    d.ca_state IN ('CA', 'NY', 'TX') 
    AND (d.ca_zip IS NOT NULL OR EXISTS (SELECT 1 FROM customer WHERE c_current_addr_sk = d.ca_address_sk))
GROUP BY 
    d.ca_city
HAVING 
    COUNT(DISTINCT d.ca_address_id) > (SELECT COUNT(*) FROM customer) * 0.1
ORDER BY 
    distinct_addresses DESC;
