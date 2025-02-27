
WITH RecursiveSales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sales_price > (
            SELECT AVG(ws_sales_price) FROM web_sales
        )
), ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_color, ''), 'Unknown') AS item_color
    FROM
        item i
    WHERE
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
), SalesSummary AS (
    SELECT
        rs.ws_order_number,
        id.i_item_desc,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS distinct_items
    FROM
        RecursiveSales rs
    JOIN
        ItemDetails id ON rs.ws_item_sk = id.i_item_sk
    GROUP BY
        rs.ws_order_number, id.i_item_desc
    HAVING
        total_sales IS NOT NULL AND total_quantity > 5
)
SELECT
    ss.ws_order_number,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN ss.distinct_items > 1 THEN 'Multi-Item'
        ELSE 'Single-Item'
    END AS item_category,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM store_returns sr WHERE sr.sr_ticket_number = ss.ws_order_number
        ) THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM
    SalesSummary ss
LEFT JOIN
    customer_demographics cd ON ss.ws_order_number % 100 = cd.cd_demo_sk % 100
WHERE
    (ss.total_sales - ss.total_quantity * 2) > 0
    AND cd.cd_gender IN ('M', 'F')
ORDER BY
    ss.total_sales DESC, ss.ws_order_number;
