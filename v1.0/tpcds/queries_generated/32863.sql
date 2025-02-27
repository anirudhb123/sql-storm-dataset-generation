
WITH RECURSIVE sales_summary AS (
    SELECT
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales
    GROUP BY
        s_store_sk
),
popular_items AS (
    SELECT
        ss_item_sk,
        COUNT(ss_ticket_number) AS transaction_count,
        RANK() OVER (ORDER BY COUNT(ss_ticket_number) DESC) AS item_rank
    FROM
        store_sales
    GROUP BY
        ss_item_sk
    HAVING
        COUNT(ss_ticket_number) > 10
),
avg_sales AS (
    SELECT
        s_store_sk,
        AVG(total_sales) AS avg_sales_per_store
    FROM
        sales_summary
    GROUP BY
        s_store_sk
),
full_summary AS (
    SELECT
        s.s_store_sk,
        s.total_sales,
        s.total_transactions,
        i.i_item_id,
        i.i_product_name,
        p.popup_name,
        coalesce(ps.transaction_count, 0) AS popular_item_count,
        avg.avg_sales_per_store
    FROM
        sales_summary s
    LEFT JOIN popular_items ps ON ps.ss_item_sk = s.s_store_sk
    JOIN item i ON i.i_item_sk = s.s_store_sk
    JOIN promotion p ON p.p_promo_sk = (SELECT MAX(p_promo_sk) FROM promotion WHERE p_item_sk = i.i_item_sk)
    JOIN avg_sales avg ON avg.s_store_sk = s.s_store_sk
    WHERE
        avg.avg_sales_per_store > 100
)
SELECT
    f.s_store_sk,
    f.total_sales,
    f.total_transactions,
    f.i_item_id,
    f.i_product_name,
    f.popular_item_count,
    CASE 
        WHEN f.total_sales IS NULL THEN 'No Sales'
        ELSE f.total_sales::VARCHAR
    END AS sales_status,
    f.avg_sales_per_store
FROM
    full_summary f
ORDER BY
    f.total_sales DESC;
