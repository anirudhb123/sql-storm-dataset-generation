
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_bill_customer_sk,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        ci.i_item_desc,
        ci.i_current_price
    FROM
        RankedSales rs
    JOIN item ci ON rs.ws_item_sk = ci.i_item_sk
    WHERE
        rs.rank <= 5 
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ci.c_customer_id,
    ci.ca_city,
    ci.ca_state,
    tsi.ws_item_sk,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_profit,
    CASE
        WHEN tsi.total_profit IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status,
    COALESCE(sp.sm_type, 'Unknown') AS shipping_type
FROM
    TopSellingItems tsi
JOIN CustomerInfo ci ON tsi.ws_bill_customer_sk = ci.c_customer_id
LEFT JOIN ship_mode sp ON tsi.ws_item_sk = sp.sm_ship_mode_sk
WHERE
    (UPPER(ci.cd_gender) = 'F' AND ci.cd_marital_status = 'M')
    OR (UPPER(ci.cd_gender) = 'M' AND ci.cd_credit_rating = 'Good')
ORDER BY
    tsi.total_profit DESC, ci.ca_city ASC;
