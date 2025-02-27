
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        1 AS level
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ah.level + 1
    FROM 
        customer_address a
    JOIN 
        AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_country = ah.ca_country
    WHERE 
        a.ca_city IS NOT NULL 
        AND ah.level < 5
),
IncomeEstimate AS (
    SELECT 
        cd_demo_sk,
        SUM(CASE 
            WHEN ib_income_band_sk IS NULL THEN 0 
            ELSE (ib_upper_bound + ib_lower_bound) / 2 
        END) AS avg_income
    FROM 
        customer_demographics cd 
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd_demo_sk
),
SalesPerformance AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_sell_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim) - 1)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_order
    FROM 
        SalesPerformance
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    tsi.ws_item_sk,
    tsi.total_sales,
    ie.avg_income,
    ROW_NUMBER() OVER (PARTITION BY ah.ca_city, ah.ca_state ORDER BY tsi.total_sales DESC) AS city_rank
FROM 
    AddressHierarchy ah
JOIN 
    TopSellingItems tsi ON tsi.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_date_sk = ah.ca_address_sk)
JOIN 
    IncomeEstimate ie ON ie.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ah.ca_address_sk)
WHERE 
    (ah.ca_country = 'US' OR ah.ca_country IS NULL)
    AND tsi.total_sales > (SELECT AVG(total_sales) FROM SalesPerformance)
ORDER BY 
    ah.ca_city, city_rank
LIMIT 100;
