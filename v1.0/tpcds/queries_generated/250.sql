
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS SalesRank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2400 AND 2405
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.full_name, 
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM CustomerInfo ci
    JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_order_number
    WHERE rs.SalesRank = 1
    GROUP BY ci.c_customer_sk, ci.full_name
    HAVING SUM(rs.ws_net_profit) > 1000
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS overall_net_profit,
    CASE 
        WHEN ci.hd_income_band_sk IS NULL THEN 'Unknown' 
        ELSE CONCAT('Income Band: ', ci.hd_income_band_sk)
    END AS income_band
FROM HighValueCustomers hvc
JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
JOIN CustomerInfo ci ON hvc.c_customer_sk = ci.c_customer_sk
GROUP BY ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.hd_income_band_sk
ORDER BY overall_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
