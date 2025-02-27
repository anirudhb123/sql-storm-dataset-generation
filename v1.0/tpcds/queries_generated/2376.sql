
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_item_sk
), 
CustomerData AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopSellingItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM
        SalesData sd
)
SELECT
    tsi.ws_item_sk,
    ti.i_product_name,
    tsi.total_quantity,
    tsi.total_profit,
    cd.cd_gender,
    cd.cd_income_band_sk,
    cd.cd_marital_status,
    cd.dep_count
FROM
    TopSellingItems tsi
JOIN
    item ti ON tsi.ws_item_sk = ti.i_item_sk
LEFT JOIN
    web_sales ws ON ws.ws_item_sk = tsi.ws_item_sk
LEFT JOIN
    CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
WHERE
    tsi.profit_rank <= 10
    AND (cd.cd_income_band_sk IS NULL OR cd.cd_income_band_sk > 1)
ORDER BY
    tsi.total_profit DESC;
