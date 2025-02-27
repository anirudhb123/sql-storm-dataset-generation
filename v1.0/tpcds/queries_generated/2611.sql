
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
AggregatedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
FinalReport AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        AVG(RS.ws_sales_price) AS avg_sales_price,
        COALESCE(SUM(AR.total_returns), 0) AS total_item_returns,
        SUM(RS.ws_quantity) AS total_items_sold,
        SUM(RS.ws_sales_price) AS total_sales_value
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        RankedSales RS ON c.c_customer_sk = RS.ws_order_number
    LEFT JOIN
        AggregatedReturns AR ON RS.ws_order_number = AR.sr_item_sk
    WHERE
        c.c_birth_country = 'USA'
    GROUP BY
        ca.ca_city
)
SELECT
    city,
    num_customers,
    avg_sales_price,
    total_item_returns,
    total_items_sold,
    total_sales_value,
    CASE
        WHEN total_items_sold = 0 THEN 0
        ELSE total_sales_value / total_items_sold
    END AS avg_order_value
FROM
    FinalReport
WHERE
    num_customers > 10
ORDER BY
    avg_sales_price DESC
LIMIT 50;
