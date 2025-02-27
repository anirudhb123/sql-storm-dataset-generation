
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT * FROM CustomerSales
    WHERE sales_rank <= 10
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
CustomerDetails AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        tc.total_spent
    FROM TopCustomers tc
    JOIN CustomerAddress ca ON tc.c_customer_sk = c.c_customer_sk
    JOIN CustomerDemographics cd ON tc.c_customer_sk = c.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_spent,
    CASE 
        WHEN cd.total_spent IS NULL THEN 'No Purchases'
        WHEN cd.total_spent > 5000 THEN 'High Value Customer'
        WHEN cd.total_spent > 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM CustomerDetails cd
ORDER BY cd.total_spent DESC;

-- Benchmarking Query
SELECT 
    SUM(ws.ws_ext_sales_price) AS total_sales,
    sm.sm_type AS shipping_method,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS avg_profit,
    (SELECT COUNT(DISTINCT ws_item_sk)
     FROM web_sales
     WHERE ws_sold_date_sk BETWEEN (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT min(d_date_sk) FROM date_dim WHERE d_year = 2023)) AS items_sold_last_year
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY sm.sm_type
HAVING total_sales > (SELECT AVG(total_sales) FROM (
    SELECT SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_ship_mode_sk
) AS avg_sales);
