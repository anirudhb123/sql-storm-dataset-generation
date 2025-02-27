
WITH RECURSIVE SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        MIN(ws_sold_date_sk) AS first_sale_date,
        MAX(ws_sold_date_sk) AS last_sale_date,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
), 
CustomerTrends AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk
),
ItemPromotions AS (
    SELECT
        i.i_item_sk,
        p.p_promo_id,
        SUM(ws.ws_quantity) AS promo_sales
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        p.p_start_date_sk <= ws.ws_sold_date_sk AND p.p_end_date_sk >= ws.ws_sold_date_sk
    GROUP BY
        i.i_item_sk, p.p_promo_id
)
SELECT
    c.c_customer_sk,
    ct.total_orders,
    ct.total_spent,
    COALESCE(MAX(it.promo_sales), 0) AS total_promo_sales,
    sd.total_quantity,
    sd.total_sales,
    sd.first_sale_date,
    sd.last_sale_date
FROM
    CustomerTrends ct
JOIN
    customer c ON ct.c_customer_sk = c.c_customer_sk
LEFT JOIN
    SalesData sd ON sd.ws_item_sk = (
        SELECT ws_item_sk FROM web_sales ws
        WHERE ws.ws_ship_customer_sk = c.c_customer_sk
        ORDER BY ws.ws_sold_date_sk DESC
        LIMIT 1
    )
LEFT JOIN
    ItemPromotions it ON it.i_item_sk = sd.ws_item_sk
WHERE
    ct.total_orders > 1
ORDER BY
    ct.total_spent DESC
LIMIT 10;
