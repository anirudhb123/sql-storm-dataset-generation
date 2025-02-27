
WITH sales_data AS (
    SELECT
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.ext_sales_price) AS total_sales,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.sold_date_sk, ws.item_sk
),
customer_data AS (
    SELECT
        cd.cd_gender,
        SUM(sd.total_quantity) AS gender_total_quantity,
        SUM(sd.total_sales) AS gender_total_sales,
        SUM(sd.total_profit) AS gender_total_profit
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN
        sales_data sd ON c.c_customer_sk = sd.item_sk   -- Adjusting this join condition as per expected data relationships
    GROUP BY
        cd.cd_gender
)
SELECT
    cd.cd_gender,
    cd.gender_total_quantity,
    cd.gender_total_sales,
    cd.gender_total_profit,
    COALESCE(cd.gender_total_sales / NULLIF(cd.gender_total_quantity, 0), 0) AS average_sales_per_item,
    COALESCE(cd.gender_total_profit / NULLIF(cd.gender_total_quantity, 0), 0) AS average_profit_per_item
FROM
    customer_data cd
WHERE
    cd.gender_total_quantity > 0
ORDER BY
    cd.gender_total_sales DESC;
