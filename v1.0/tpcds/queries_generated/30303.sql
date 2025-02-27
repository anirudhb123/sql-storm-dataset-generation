
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        w.ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales w
    WHERE w.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3)
    )
    GROUP BY w.ws_web_page_sk
),
AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        AVG(ca_gmt_offset) AS average_gmt_offset
    FROM customer_address
    GROUP BY ca_state
),
DemographicData AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_deps,
        SUM(cd_dep_college_count) AS college_deps,
        COUNT(cd_demo_sk) AS demo_count
    FROM customer_demographics
    GROUP BY cd_gender
)
SELECT 
    coalesce(ch.c_first_name, 'Unknown') AS Customer_First_Name,
    coalesce(ch.c_last_name, 'Unknown') AS Customer_Last_Name,
    coalesce(sd.total_sales, 0) AS Total_Sales,
    sd.order_count AS Order_Count,
    asum.address_count AS Address_Count,
    asum.average_gmt_offset AS Avg_GMT_Offset,
    ddata.total_deps AS Total_DEP,
    ddata.college_deps AS College_DEPS,
    ddata.demo_count AS Demo_Count
FROM CustomerHierarchy ch
LEFT JOIN SalesData sd ON sd.ws_web_page_sk = ch.c_current_cdemo_sk
LEFT JOIN AddressSummary asum ON asum.ca_state = (
    SELECT ca_state 
    FROM customer_address 
    WHERE ca_address_sk = ch.c_current_addr_sk
    LIMIT 1
)
JOIN DemographicData ddata ON ddata.cd_gender = (
    SELECT cd_gender 
    FROM customer_demographics 
    WHERE cd_demo_sk = ch.c_current_cdemo_sk
    LIMIT 1
)
WHERE ch.level < 5
ORDER BY total_sales DESC
LIMIT 100;
