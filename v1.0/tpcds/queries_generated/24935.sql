
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
AggregateSales AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        AVG(rs.ws_sales_price) AS average_price
    FROM
        RankedSales rs
    WHERE
        rs.rn = 1
    GROUP BY
        rs.ws_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_current_addr_sk
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender IS NULL OR cd.cd_marital_status IN ('M', 'S')
),
AddressInfo AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer_address ca
    WHERE
        ca.ca_zip IS NOT NULL AND
        ca.ca_state IN ('CA', 'NY')
),
ReturnedItems AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)
SELECT
    DISTINCT ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    COALESCE(asales.average_price, 0) AS average_price,
    COALESCE(r.total_returns, 0) AS total_returns
FROM
    CustomerInfo ci
LEFT JOIN
    AddressInfo ai ON ci.c_current_addr_sk = ai.ca_address_sk
LEFT JOIN
    AggregateSales asales ON ai.ca_zip = (SELECT DISTINCT ca.ca_zip 
                                           FROM customer_address ca 
                                           WHERE ca.ca_address_sk = ci.c_current_addr_sk)
LEFT JOIN
    ReturnedItems r ON asales.ws_item_sk = r.sr_item_sk
WHERE
    ai.ca_city IS NOT NULL 
    AND (asales.average_price IS NOT NULL OR r.total_returns IS NOT NULL)
    AND (ci.c_first_name LIKE '%a%' OR ci.c_last_name LIKE '%z%')
ORDER BY
    ci.c_customer_sk DESC
LIMIT 100; 
