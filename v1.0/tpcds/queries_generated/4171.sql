
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_profit DESC) as rank,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_count
    FROM
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        LEFT JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
        AND NOT (ws.ws_net_profit IS NULL OR ws.ws_net_profit = 0)
    GROUP BY
        ws.ws_order_number, ws.ws_quantity, ws.ws_net_profit, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
),
summary AS (
    SELECT
        city,
        state,
        gender,
        marital_status,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(total_returns) AS avg_returns,
        AVG(web_returns_count) AS avg_web_returns
    FROM (
        SELECT 
            ca.ca_city AS city,
            ca.ca_state AS state,
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            ws.ws_quantity,
            ws.ws_net_profit,
            ranked_sales.total_returns,
            ranked_sales.web_returns_count
        FROM
            ranked_sales
        JOIN customer_address ca ON ranked_sales.ca_city = ca.ca_city
        JOIN customer_demographics cd ON ranked_sales.cd_gender = cd.cd_gender and ranked_sales.marital_status = cd.cd_marital_status
    ) AS sales_summary
    GROUP BY
        city, state, gender, marital_status
)
SELECT
    city,
    state,
    gender,
    marital_status,
    total_quantity,
    total_net_profit,
    avg_returns,
    avg_web_returns
FROM
    summary
WHERE
    total_net_profit > 5000
ORDER BY 
    total_net_profit DESC
LIMIT 10;
