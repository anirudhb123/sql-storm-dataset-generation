
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY
        ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) + c.total_quantity AS total_quantity,
        SUM(s.ss_net_paid) + c.total_sales AS total_sales
    FROM
        store_sales s
    JOIN
        SalesCTE c ON s.ss_sold_date_sk = c.ss_sold_date_sk AND s.ss_item_sk = c.ss_item_sk
    WHERE
        s.ss_sold_date_sk < c.ss_sold_date_sk
    GROUP BY
        s.ss_sold_date_sk, s.ss_item_sk
),
AggregatedSales AS (
    SELECT
        s.ss_item_sk,
        SUM(s.total_quantity) AS overall_quantity,
        SUM(s.total_sales) AS overall_sales
    FROM
        SalesCTE s
    GROUP BY
        s.ss_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        a.overall_quantity,
        a.overall_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY a.overall_sales DESC) AS sales_rank
    FROM
        item i
    LEFT JOIN
        AggregatedSales a ON i.i_item_sk = a.ss_item_sk
    WHERE
        i.i_current_price IS NOT NULL
)
SELECT
    id.i_item_id,
    id.i_item_desc,
    COALESCE(id.overall_quantity, 0) AS quantity_sold,
    COALESCE(id.overall_sales, 0) AS total_sales,
    CASE 
        WHEN id.overall_sales > 10000 THEN 'High Performer'
        WHEN id.overall_sales BETWEEN 5000 AND 10000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM
    ItemDetails id
WHERE
    id.sales_rank = 1
ORDER BY
    id.total_sales DESC
LIMIT 10;
