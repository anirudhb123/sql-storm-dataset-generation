
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_quarter_seq = 2
        )
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        o.order_count,
        COALESCE(CAST(SUM(ws.ws_ext_sales_price) AS DECIMAL(10, 2)), 0) AS total_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            COUNT(*) AS order_count
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) o ON c.c_customer_sk = o.ws_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, o.order_count
),
SalesStats AS (
    SELECT
        csr.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS average_price,
        MAX(ws.ws_ext_sales_price) AS max_price,
        MIN(ws.ws_ext_sales_price) AS min_price
    FROM
        CustomerInfo csr
    JOIN web_sales ws ON csr.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY
        csr.c_customer_id
)
SELECT
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_orders,
    ss.total_quantity,
    ss.average_price,
    ss.max_price,
    ss.min_price,
    CASE
        WHEN ss.total_quantity > 100 THEN 'High Volume'
        WHEN ss.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM
    CustomerInfo cs
LEFT JOIN SalesStats ss ON cs.c_customer_id = ss.c_customer_id
WHERE
    (cs.cd_gender = 'F' OR cs.cd_marital_status = 'S')
    AND cs.total_spent > 500
ORDER BY
    cs.total_spent DESC
LIMIT 100;
