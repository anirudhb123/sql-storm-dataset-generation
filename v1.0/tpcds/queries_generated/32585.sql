
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
        JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)

SELECT 
    cha.c_city,
    COUNT(DISTINCT cu.c_customer_sk) AS total_customers,
    SUM(COALESCE(cd.cd_purchase_estimate, 0)) AS total_purchase_estimate,
    AVG(CASE 
            WHEN cd.cd_credit_rating = 'M' THEN cd.cd_purchase_estimate 
            ELSE NULL 
        END) AS avg_purchase_estimate_marital,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names
FROM 
    customer_address cha 
LEFT JOIN 
    customer cu ON cha.ca_address_sk = cu.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_hierarchy ch ON cu.c_customer_sk = ch.c_customer_sk
WHERE 
    cha.ca_city IS NOT NULL 
    AND cha.ca_state = 'CA'
GROUP BY 
    cha.c_city
HAVING 
    COUNT(cu.c_customer_sk) > 10
ORDER BY 
    total_purchase_estimate DESC
LIMIT 10;

SELECT 
    'Store Sales' AS data_source,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM 
    store_sales ss
WHERE 
    ss.ss_sales_price > 100
UNION ALL
SELECT 
    'Web Sales' AS data_source,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    web_sales ws
WHERE 
    ws.ws_sales_price > 100;

WITH high_income_customers AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE 
        hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000)
    GROUP BY 
        hd.hd_demo_sk
    HAVING 
        COUNT(c.c_customer_sk) > 5
)

SELECT 
    COUNT(*) AS high_income_customer_count,
    AVG(hd.hd_buy_potential) AS avg_buy_potential
FROM 
    high_income_customers hic
JOIN 
    household_demographics hd ON hic.hd_demo_sk = hd.hd_demo_sk;
