
WITH SalesData AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM
        catalog_sales cs
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1975 AND 1990
        AND i.i_current_price > 10.00
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_item_sk
),
WarehouseSales AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_net_paid) AS total_sales_value
    FROM
        inventory inv
    JOIN 
        SalesData sd ON inv.inv_item_sk = sd.cs_item_sk
    GROUP BY
        inv.inv_warehouse_sk
),
SalesByWarehouse AS (
    SELECT
        w.w_warehouse_id,
        ws.total_quantity_sold,
        ws.total_sales_value
    FROM
        warehouse w
    LEFT JOIN
        WarehouseSales ws ON w.w_warehouse_sk = ws.inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    COALESCE(ws.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ws.total_sales_value, 0) AS total_sales_value,
    ROUND((COALESCE(ws.total_sales_value, 0) / NULLIF(ws.total_quantity_sold, 0)), 2) AS average_sales_price
FROM
    warehouse w
LEFT JOIN
    SalesByWarehouse ws ON w.w_warehouse_sk = ws.inv_warehouse_sk
ORDER BY
    w.w_warehouse_id;
