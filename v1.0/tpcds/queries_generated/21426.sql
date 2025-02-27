
WITH RECURSIVE IncomeRanges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
),
RelevantDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating IS NULL THEN 1 ELSE 0 END) AS null_credit_count
    FROM customer_demographics
    WHERE cd_dep_count > 0
    GROUP BY cd_gender, cd_marital_status
),
MaxSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_profit) > (SELECT AVG(total_net_profit) FROM (
        SELECT SUM(ws_net_profit) AS total_net_profit
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) AS subquery)
),
JoinedData AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        rd.total_net_profit,
        ARRAY_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name)) AS customer_names
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN RelevantDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN MaxSales rd ON c.c_customer_sk = rd.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    jd.ca_city AS city,
    jd.ca_state AS state,
    jd.cd_gender,
    jd.cd_marital_status,
    COUNT(jd.c_customer_sk) AS customer_count,
    SUM(COALESCE(jd.total_net_profit, 0)) AS total_net_profit,
    STRING_AGG(DISTINCT jd.customer_names) AS customer_names
FROM JoinedData jd
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = (
    SELECT sm_ship_mode_sk 
    FROM catalog_sales cs 
    WHERE cs.cs_ship_mode_sk IS NOT NULL 
    AND cs.cs_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = jd.c_customer_sk)
    ORDER BY cs.cs_sales_price DESC 
    LIMIT 1
)
WHERE jd.cd_gender = 'F' OR (jd.cd_marital_status IS NULL AND jd.total_net_profit > 5000)
GROUP BY jd.ca_city, jd.ca_state, jd.cd_gender, jd.cd_marital_status
HAVING COUNT(jd.c_customer_sk) > 5
ORDER BY total_net_profit DESC,
         city DESC NULLS LAST
OFFSET 2 ROWS FETCH NEXT 10 ROWS ONLY;
