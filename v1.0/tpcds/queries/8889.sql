
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        CAST(d.d_date AS DATE) AS sales_date
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_item_sk, ws.ws_order_number, d.d_date
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM
        item i
),
WarehouseSales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        store s
    JOIN
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY
        s.s_store_sk, s.s_store_name
)
SELECT
    ItemDetails.i_item_desc,
    ItemDetails.i_brand,
    ItemDetails.i_category,
    SalesData.sales_date,
    SalesData.total_sales,
    SalesData.total_quantity,
    SalesData.total_discount,
    WarehouseSales.s_store_name,
    WarehouseSales.order_count,
    WarehouseSales.total_profit
FROM
    SalesData
JOIN
    ItemDetails ON SalesData.ws_item_sk = ItemDetails.i_item_sk
JOIN
    WarehouseSales ON WarehouseSales.s_store_sk = (
        SELECT ws.ws_warehouse_sk
        FROM web_sales ws
        WHERE ws.ws_order_number = SalesData.ws_order_number
        LIMIT 1
    )
ORDER BY
    SalesData.total_sales DESC
LIMIT 100;
