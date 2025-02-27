
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS orders_count
    FROM web_sales
    WHERE ws_sold_date_sk >= 2458850 -- Example date for the start of FY 2023
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE
            WHEN cd.cd_dep_count IS NULL THEN 'N/A'
            ELSE CAST(cd.cd_dep_count AS VARCHAR)
        END AS dependents,
        ca.ca_city,
        COALESCE(ca.ca_state, 'UNKNOWN') AS state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesRank AS (
    SELECT 
        ss.ws_bill_customer_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ss.ws_bill_customer_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    GROUP BY ss.ws_bill_customer_sk
),
SelectedCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.dependents,
        cd.state,
        ss.total_sales,
        COALESCE(sr.total_net_profit, 0) AS total_net_profit,
        sr.profit_rank
    FROM CustomerDetails cd
    LEFT JOIN SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN SalesRank sr ON cd.c_customer_sk = sr.ws_bill_customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.city,
    c.state,
    COALESCE(c.total_sales, 0) AS total_sales,
    CASE 
        WHEN c.total_net_profit > 50000 THEN 'High Value'
        WHEN c.total_sales IS NULL AND c.dependents = 'N/A' THEN 'No Sales Records'
        ELSE 'Regular'
    END AS customer_segment,
    c.profit_rank
FROM SelectedCustomers c
WHERE c.total_sales > 1000
  OR c.dependents <> 'N/A'
ORDER BY c.total_sales DESC, c.profit_rank ASC
LIMIT 50;
