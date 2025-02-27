
WITH RECURSIVE profit_analysis AS (
    SELECT
        ws_order_number,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales
    GROUP BY
        ws_order_number
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        COALESCE(NULLIF(c.c_first_name, ''), '(unknown)') AS first_name,
        COALESCE(NULLIF(c.c_last_name, ''), '(unknown)') AS last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_customer_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT
    cur.cust_id,
    cust.first_name,
    cust.last_name,
    cust.cd_gender,
    cur.total_profit,
    cur.order_count,
    ROW_NUMBER() OVER (PARTITION BY cur.cd_gender ORDER BY cur.total_profit DESC) AS gender_profit_rank
FROM
    customer_summary cust
    LEFT JOIN (
        SELECT
            c.c_customer_id AS cust_id,
            SUM(pa.total_profit) AS total_profit,
            COUNT(pa.ws_order_number) AS order_count
        FROM
            customer c
            LEFT JOIN profit_analysis pa ON c.c_customer_sk = pa.ws_order_number
        GROUP BY
            c.c_customer_id
    ) cur ON cust.c_customer_id = cur.cust_id
WHERE
    (cur.total_profit IS NOT NULL AND cur.total_profit > 0)
    OR (cur.total_profit IS NULL AND cust.total_customer_profit IS NOT NULL)
    OR (cust.order_count > 5 AND cust.cd_gender = 'F')
UNION ALL
SELECT
    NULL AS cust_id,
    NULL AS first_name,
    NULL AS last_name,
    NULL AS cd_gender,
    SUM(COALESCE(cur.total_profit, 0)) AS total_profit,
    COUNT(DISTINCT cur.cust_id) AS order_count
FROM
    customer_summary cur
WHERE
    cur.order_count < 3
GROUP BY
    cur.cd_gender
ORDER BY
    total_profit DESC, order_count DESC;
