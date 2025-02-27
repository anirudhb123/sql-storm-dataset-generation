
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ra.total_profit,
        ra.order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN RankedSales ra ON c.c_customer_sk = ra.ws_bill_customer_sk
    WHERE ra.profit_rank <= 10
),
CustomerAddresses AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        COALESCE(SUBSTRING(ca.ca_street_name, 1, 20), 'Unknown') AS short_street_name
    FROM customer_address ca
    WHERE ca.ca_country IS NOT NULL
),
TotalSales AS (
    SELECT 
        SUM(ws.net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy = 11
    )
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_profit,
    tc.order_count,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    ca.ca_zip,
    ts.total_net_profit,
    CASE 
        WHEN tc.total_profit > (ts.total_net_profit / 100) THEN 'High Value'
        ELSE 'Regular'
    END AS customer_value
FROM TopCustomers tc
JOIN CustomerAddresses ca ON tc.c_customer_sk = ca.ca_address_sk
CROSS JOIN TotalSales ts
ORDER BY tc.total_profit DESC, tc.order_count DESC;
