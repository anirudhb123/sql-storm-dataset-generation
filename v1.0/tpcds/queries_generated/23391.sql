
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        cd.cd_gender,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        COALESCE(hd.hd_dep_count, 0) AS dependent_count
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT
        item.i_item_id,
        SUM(ws_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        item
    JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY
        item.i_item_id
)
SELECT
    cd.c_customer_sk,
    cd.c_birth_month,
    cd.cd_gender,
    CASE
        WHEN COUNT(r.rn) > 0 THEN 'Returned'
        WHEN COUNT(s.total_orders) > 0 THEN 'Purchased'
        ELSE 'No Activity'
    END AS customer_activity,
    SUM(CASE WHEN r.total_returned_quantity IS NOT NULL THEN r.total_returned_quantity ELSE 0 END) AS total_returned,
    SUM(CASE WHEN s.total_sales_price IS NOT NULL THEN s.total_sales_price ELSE 0 END) AS total_sales
FROM
    CustomerDetails cd
LEFT JOIN RankedReturns r ON cd.c_customer_sk = r.sr_customer_sk
LEFT JOIN SalesData s ON s.i_item_id IN (
    SELECT item.i_item_id FROM item
    WHERE item.i_item_id LIKE 'A%'
)
GROUP BY
    cd.c_customer_sk,
    cd.c_birth_month,
    cd.cd_gender
HAVING 
    (SUM(r.total_returned) > 10 OR SUM(s.total_sales) > 1000) 
    AND (cd.cd_gender IS NOT NULL OR cd.c_birth_month IS NULL)
ORDER BY
    total_sales DESC NULLS LAST,
    customer_activity;
