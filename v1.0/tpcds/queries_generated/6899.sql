
WITH SalesData AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS active_days
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 -- Filter for the current year
        AND c.c_preferred_cust_flag = 'Y' -- Only preferred customers
    GROUP BY
        c.c_customer_id
),
Demographics AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT sd.c_customer_id) AS customer_count,
        AVG(sd.total_profit) AS avg_profit,
        MAX(sd.total_orders) AS max_orders,
        MIN(sd.active_days) AS min_active_days
    FROM
        SalesData sd
    JOIN
        customer_demographics cd ON sd.c_customer_id = cd.cd_demo_sk -- Assuming mapping exists
    GROUP BY
        cd.cd_gender
)
SELECT
    d.cd_gender,
    d.customer_count,
    d.avg_profit,
    d.max_orders,
    d.min_active_days
FROM
    Demographics d
ORDER BY
    d.customer_count DESC
LIMIT 10; 
