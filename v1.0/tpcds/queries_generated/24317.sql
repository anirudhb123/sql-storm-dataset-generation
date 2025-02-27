
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS site_rank
    FROM
        web_sales AS ws
    JOIN
        customer AS c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year IS NOT NULL
        AND (c.c_birth_month BETWEEN 1 AND 12 OR c.c_birth_day IS NULL)
    GROUP BY
        ws.web_site_sk, ws.web_site_id
),
TopWebSites AS (
    SELECT
        web_site_id,
        total_net_profit
    FROM
        RankedSales
    WHERE
        site_rank <= 5
),
SalesWithDetails AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        dp.d_date,
        c.cc_name,
        sm.sm_type,
        COALESCE(sr.return_quantity, 0) AS total_returns
    FROM
        web_sales AS ws
    LEFT JOIN
        date_dim AS dp ON ws.ws_sold_date_sk = dp.d_date_sk
    LEFT JOIN
        store_returns AS sr ON ws.ws_order_number = sr.sr_ticket_number
    JOIN
        call_center AS cc ON ws.ws_ship_cdemo_sk = cc.cc_call_center_sk
    JOIN
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        dp.d_year = 2022
        AND (sm.sm_type = 'Standard Class' OR sm.sm_carrier IS NULL)
)
SELECT
    swd.ws_order_number,
    SUM(swd.ws_quantity) AS total_items_sold,
    SUM(swd.ws_net_profit) AS total_net_profit,
    AVG(swd.total_returns) AS average_returns,
    STRING_AGG(DISTINCT wd.web_name, ', ') AS associated_websites
FROM
    SalesWithDetails AS swd
JOIN
    TopWebSites AS tws ON tws.web_site_id = swd.ws_order_number
WHERE
    (swd.total_returns > 0 AND swd.ws_net_profit IS NOT NULL)
    OR (swd.ws_quantity > 10 AND swd.ws_net_profit < 0)
GROUP BY
    swd.ws_order_number
HAVING
    SUM(swd.ws_net_profit) > 1000
ORDER BY
    total_net_profit DESC
LIMIT 10;
