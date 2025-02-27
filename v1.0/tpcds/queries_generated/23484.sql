
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateSales AS (
    SELECT
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_ship_customer_sk
),
TopCustomers AS (
    SELECT
        rc.c_customer_id,
        AS.total_profit,
        AS.order_count,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM
        RankedCustomers rc
    JOIN
        AggregateSales AS ON rc.c_customer_sk = AS.ws_ship_customer_sk
    WHERE
        rc.gender_rank <= 10
)
SELECT
    tc.c_customer_id,
    tc.total_profit,
    tc.order_count,
    CASE
        WHEN tc.total_profit > 1000 THEN 'High Roller'
        WHEN tc.order_count < 5 THEN 'Newbie'
        ELSE 'Regular'
    END AS customer_category
FROM
    TopCustomers tc
JOIN
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
LEFT JOIN
    store s ON ca.ca_address_sk = s.s_store_sk
WHERE
    EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk BETWEEN 20000101 AND 20001231
          AND ss.ss_customer_sk = tc.ws_ship_customer_sk
          AND ss.ss_quantity > (
              SELECT AVG(ss_inner.ss_quantity)
              FROM store_sales ss_inner
              WHERE ss_inner.ss_customer_sk = ss.ss_customer_sk
          )
    )
ORDER BY
    tc.total_profit DESC,
    tc.order_count ASC;
