
WITH customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.ca_state,
        ad.ca_city,
        hd.hd_income_band_sk
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
), combined_data AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.ca_state,
        cd.ca_city,
        hd.hd_income_band_sk,
        ss.total_net_profit,
        ss.total_orders
    FROM
        customer_data cd
    LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    AVG(ss.total_net_profit) AS avg_net_profit,
    SUM(ss.total_orders) AS total_orders
FROM 
    combined_data cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT cd.c_customer_sk) > 10
ORDER BY 
    avg_net_profit DESC, customer_count DESC
LIMIT 100;
