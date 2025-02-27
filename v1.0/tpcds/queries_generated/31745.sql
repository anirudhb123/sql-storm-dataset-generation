
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit, 
        COUNT(ws_order_number) AS order_count 
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT
        cs_bill_customer_sk, 
        SUM(cs_net_profit) AS total_net_profit, 
        COUNT(cs_order_number) AS order_count 
    FROM catalog_sales 
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs_bill_customer_sk
    HAVING SUM(cs_net_profit) > 1000
), customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        sa.ca_city,
        sa.ca_state,
        si.total_net_profit,
        si.order_count
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
    LEFT JOIN sales_summary si ON c.c_customer_sk = si.ws_bill_customer_sk OR c.c_customer_sk = si.cs_bill_customer_sk
), ranked_customers AS (
    SELECT 
        ci.*, 
        RANK() OVER (PARTITION BY ci.ca_state ORDER BY ci.total_net_profit DESC) AS rank_within_state 
    FROM customer_info ci
    WHERE ci.total_net_profit IS NOT NULL
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.ca_state,
    rc.total_net_profit,
    rc.order_count,
    rc.rank_within_state
FROM ranked_customers rc
WHERE rc.rank_within_state <= 5
ORDER BY rc.ca_state, rc.total_net_profit DESC;
