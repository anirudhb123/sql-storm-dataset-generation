
WITH RankedSales AS (
    SELECT
        w.w_warehouse_id,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS order_count
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
TopSales AS (
    SELECT
        rs.w_warehouse_id,
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.price_rank,
        rs.order_count
    FROM
        RankedSales rs
    WHERE
        rs.price_rank <= 5
    AND rs.order_count > 2
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE
        hd.hd_income_band_sk IS NOT NULL
),
SalesSummary AS (
    SELECT
        ts.w_warehouse_id,
        COUNT(DISTINCT ts.ws_order_number) AS total_orders,
        SUM(ts.ws_sales_price) AS total_sales
    FROM
        TopSales ts
    GROUP BY
        ts.w_warehouse_id
),
FinalReport AS (
    SELECT
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.marital_status,
        ss.total_orders,
        ss.total_sales,
        CASE
            WHEN ss.total_sales > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_value
    FROM
        CustomerDetails cs
    LEFT JOIN
        SalesSummary ss ON cs.c_customer_id IN (SELECT DISTINCT ws_ship_customer_sk FROM web_sales)
)
SELECT
    fr.c_customer_id,
    fr.c_first_name || ' ' || fr.c_last_name AS full_name,
    fr.marital_status,
    fr.total_orders,
    COALESCE(fr.total_sales, 0) AS total_sales,
    fr.customer_value
FROM
    FinalReport fr
WHERE
    fr.total_orders IS NOT NULL
    OR fr.customer_value = 'High Value Customer'
ORDER BY
    fr.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
