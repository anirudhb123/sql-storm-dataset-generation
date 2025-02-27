
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price) > 10000
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_first_name) AS state_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
shipping_info AS (
    SELECT 
        sm.sm_carrier,
        SUM(ws.net_profit) AS carrier_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.net_profit) DESC) AS carrier_rank
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_carrier
)

SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    si.sm_carrier, 
    si.carrier_profit,
    si.order_count,
    COALESCE(sc.total_sales, 0) AS web_sales,
    COALESCE(sc.total_orders, 0) AS order_count
FROM customer_info ci
LEFT JOIN sales_cte sc ON ci.c_customer_sk = sc.ws_item_sk
INNER JOIN shipping_info si ON si.carrier_rank <= 5
WHERE ci.state_rank <= 10
ORDER BY ci.c_last_name, ci.c_first_name;
