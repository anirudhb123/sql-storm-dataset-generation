
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT
        COUNT(DISTINCT wr_returning_customer_sk) AS total_returns,
        wr_returning_addr_sk,
        SUM(wr_return_amt) AS total_return_amount
    FROM
        web_returns
    GROUP BY
        wr_returning_addr_sk
),
ShippingStatistics AS (
    SELECT
        sm.sm_ship_mode_id,
        SUM(ws_quantity) AS shipped_quantity,
        SUM(ws_net_paid) AS total_shipped_value,
        AVG(ws_net_profit) AS average_profit,
        CASE
            WHEN SUM(ws_net_paid) > 1000000 THEN 'High Value'
            WHEN SUM(ws_net_paid) BETWEEN 500000 AND 1000000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS shipping_value_category
    FROM
        web_sales ws
    JOIN
        ship_mode sm ON ws.sm_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        ws_item_sk IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0)
    GROUP BY
        sm.sm_ship_mode_id
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COALESCE(RS.web_site_sk, 0) AS site_id,
    COALESCE(CR.total_returns, 0) AS returns,
    COALESCE(CR.total_return_amount, 0) AS return_value,
    SS.shipped_quantity,
    SS.total_shipped_value,
    SS.average_profit,
    SS.shipping_value_category
FROM
    customer_address ca
LEFT JOIN
    RankedSales RS ON RS.ws_item_sk = (
        SELECT i_item_sk FROM item
        WHERE i_item_desc ILIKE '%' || ca.ca_city || '%'
        LIMIT 1
    )
LEFT JOIN
    CustomerReturns CR ON CR.wr_returning_addr_sk = ca.ca_address_sk
LEFT JOIN
    ShippingStatistics SS ON SS.sm_ship_mode_id IN (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_code IN ('AIR', 'GROUND')
    )
WHERE
    ca.ca_country IS NOT NULL AND
    (ca.ca_city IS NULL OR ca.ca_state IS NULL OR ca.ca_state = 'CA')
ORDER BY
    COALESCE(CR.total_return_amount, 0) DESC,
    SS.average_profit ASC
FETCH FIRST 50 ROWS ONLY;
