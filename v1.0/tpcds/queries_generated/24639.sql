
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        cd.cd_gender,
        ca.ca_city,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS city_profit_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ws.ws_net_profit IS NOT NULL
        AND cd.cd_gender IN ('M', 'F')
    GROUP BY
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        cd.cd_gender,
        ca.ca_city
),
TotalSales AS (
    SELECT
        sm.sm_ship_mode_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_id
),
ReturnStats AS (
    SELECT
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
)
SELECT
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_net_profit,
    r.cd_gender,
    r.ca_city,
    ts.total_sales,
    ts.order_count,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return_amount, 0.00) AS total_return_amount,
    CASE 
        WHEN r.city_profit_rank < 5 THEN 'Top City'
        ELSE 'Other City'
    END AS city_rank_category
FROM
    RankedSales r
LEFT OUTER JOIN
    TotalSales ts ON r.ws_item_sk = ts.sm_ship_mode_id
LEFT OUTER JOIN
    ReturnStats rs ON r.ws_item_sk = rs.cr_item_sk
WHERE
    r.profit_rank = 1
    AND (r.cd_gender = 'M' OR r.cd_gender IS NULL)
ORDER BY
    r.ca_city, r.ws_net_profit DESC;
