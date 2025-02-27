
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk = (
        SELECT MAX(ws_sold_date_sk) 
        FROM web_sales 
        WHERE ws_item_sk IS NOT NULL
    )
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    GROUP BY ca_state
),
MaxSales AS (
    SELECT 
        MAX(total_net_profit) AS max_profit
    FROM CustomerInfo
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_net_profit,
    asum.address_count,
    asum.avg_gmt_offset
FROM CustomerInfo ci
JOIN AddressSummary asum ON ci.c_customer_sk IN (
    SELECT ca_address_sk 
    FROM customer_address 
    WHERE ca_state IN ('CA', 'NY')
)
WHERE ci.total_net_profit = (SELECT max_profit FROM MaxSales)
ORDER BY ci.total_net_profit DESC
LIMIT 10;

SELECT 
    sm.sm_type,
    COUNT(DISTINCT ws_sales_price) AS distinct_price_count
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_sales_price IS NOT NULL
GROUP BY sm.sm_type
HAVING COUNT(DISTINCT ws.ws_sales_price) > 5
UNION ALL
SELECT 
    sm.sm_type,
    NULL AS distinct_price_count
FROM ship_mode sm 
WHERE sm.sm_type NOT IN (SELECT DISTINCT sm_type FROM web_sales ws JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk);
