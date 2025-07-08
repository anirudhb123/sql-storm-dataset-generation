
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023
            AND d.d_day_name NOT IN ('Saturday', 'Sunday')
        )
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseCustomerSales AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM
        web_sales ws
    JOIN inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    WHERE
        ws.ws_quantity > 0
        AND w.w_country = 'USA'
    GROUP BY
        w.w_warehouse_sk
),
TopRecords AS (
    SELECT
        r.rank,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        w.total_sales,
        w.order_count
    FROM
        RankedSales r
    JOIN CustomerInfo ci ON r.ws_order_number IN (
        SELECT wr_order_number
        FROM web_returns wr
        WHERE wr_returning_customer_sk = ci.c_customer_sk
    )
    JOIN WarehouseCustomerSales w ON w.w_warehouse_sk = (
        SELECT inv.inv_warehouse_sk
        FROM inventory inv
        WHERE inv.inv_item_sk = r.ws_item_sk
        LIMIT 1
    )
    WHERE
        r.rank = 1
)
SELECT
    CASE
        WHEN cd_marital_status = 'M' THEN 'Married'
        WHEN cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_amount,
    AVG(order_count) AS avg_orders
FROM
    TopRecords
WHERE
    cd_gender = 'F'
GROUP BY
    marital_status
ORDER BY
    total_sales_amount DESC
LIMIT 10;
