
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_analysis AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        AVG(ss_ext_sales_price) AS avg_sales_price,
        MAX(ss_net_profit) AS max_net_profit,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS marital_count
    FROM
        customer c
    LEFT JOIN
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
),
returns_summary AS (
    SELECT
        wr_item_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_returned_amount
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
item_performance AS (
    SELECT
        i.i_item_sk,
        COALESCE(rs.total_quantity, 0) AS total_web_sales,
        COALESCE(rs.total_net_profit, 0) AS total_web_profit,
        COALESCE(rs.item_rank, NULL) AS web_item_rank,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_returned_amount, 0) AS returned_amount
    FROM
        item i
    LEFT JOIN ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN returns_summary r ON i.i_item_sk = r.wr_item_sk
)
SELECT
    ca.ca_city,
    SUM(cp.total_sales) AS total_sales_by_city,
    AVG(cp.avg_sales_price) AS avg_sales_price_by_city,
    MAX(cp.max_net_profit) AS max_net_profit_by_city,
    STRING_AGG(DISTINCT ca.ca_state) AS unique_states
FROM
    customer_analysis cp
JOIN
    customer c ON cp.c_customer_sk = c.c_customer_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY
    ca.ca_city
HAVING
    COUNT(DISTINCT cp.c_customer_sk) > 5
ORDER BY
    total_sales_by_city DESC
LIMIT 10;
