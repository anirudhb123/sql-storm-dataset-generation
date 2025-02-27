
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM
        web_sales
),
AggregateReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_band
    FROM
        customer_demographics
    WHERE
        cd_gender IS NOT NULL
),
ItemSales AS (
    SELECT
        i_item_sk,
        i_product_name,
        SUM(ws_quantity) AS total_quantity_sold
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i_item_sk, i_product_name
)

SELECT
    ca.ca_address_id,
    ca.ca_city,
    SUM(ps.net_profit) AS total_net_profit,
    ROUND(AVG(addr.total_returned), 2) AS avg_returned_qty,
    COUNT(DISTINCT cs.cd_demo_sk) AS unique_customers,
    STRING_AGG(DISTINCT cd.gender) AS genders,
    CASE
        WHEN SUM(ps.net_profit) > 10000 THEN 'High'
        WHEN SUM(ps.net_profit) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profitability_category
FROM
    customer_address ca
LEFT JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN
    RankedSales ps ON c.c_customer_sk = ps.ws_order_number
LEFT JOIN
    AggregateReturns addr ON addr.wr_item_sk = ps.ws_item_sk
LEFT JOIN
    CustomerDemographics cs ON cs.cd_demo_sk = c.c_current_cdemo_sk
WHERE
    ca.ca_city ILIKE 'New York%'
GROUP BY
    ca.ca_address_id, ca.ca_city
HAVING
    COUNT(ps.ws_order_number) > 5
ORDER BY
    total_net_profit DESC
LIMIT 10;
