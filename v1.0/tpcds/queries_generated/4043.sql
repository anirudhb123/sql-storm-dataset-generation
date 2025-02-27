
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS ReturnRank
    FROM
        store_returns
),
TopReturns AS (
    SELECT
        rr.sr_item_sk,
        rr.sr_return_quantity,
        rr.sr_return_amt,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY rr.sr_item_sk ORDER BY rr.sr_return_amt DESC) AS ReturnAmtRank
    FROM
        RankedReturns rr
    JOIN
        customer c ON rr.sr_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        rr.ReturnRank <= 10
)
SELECT
    t.sr_item_sk,
    t.sr_return_quantity,
    t.sr_return_amt,
    IIF(t.ReturnAmtRank = 1, 'Highest Return', 'Other') AS ReturnCategory,
    COALESCE(SUM(ws.ws_net_profit), 0) AS TotalNetProfit,
    sm.sm_type AS ShippingMethod,
    DENSE_RANK() OVER (ORDER BY ca.ca_city) AS CityRank
FROM
    TopReturns t
LEFT JOIN
    web_sales ws ON ws.ws_item_sk = t.sr_item_sk
LEFT JOIN
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    t.sr_item_sk,
    t.sr_return_quantity,
    t.sr_return_amt,
    t.ReturnAmtRank,
    sm.sm_type,
    ca.ca_city
HAVING
    COALESCE(SUM(ws.ws_net_profit), 0) > 1000
ORDER BY
    TotalNetProfit DESC, 
    t.sr_return_amt DESC;
