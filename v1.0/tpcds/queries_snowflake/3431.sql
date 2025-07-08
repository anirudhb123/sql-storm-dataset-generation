
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        i.i_item_desc,
        sm.sm_type,
        DENSE_RANK() OVER (ORDER BY sd.total_net_paid DESC) AS sales_rank
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = (
        SELECT ws.ws_ship_mode_sk
        FROM web_sales ws
        WHERE ws.ws_item_sk = sd.ws_item_sk
        LIMIT 1
    )
)
SELECT
    t.ws_item_sk,
    t.total_quantity,
    t.total_net_paid,
    COALESCE(t.i_item_desc, 'Unknown') AS item_description,
    COALESCE(t.sm_type, 'Not Specified') AS shipping_mode,
    CASE
        WHEN t.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM TopSales t
WHERE t.sales_rank <= 10
ORDER BY t.total_net_paid DESC
LIMIT 20;
