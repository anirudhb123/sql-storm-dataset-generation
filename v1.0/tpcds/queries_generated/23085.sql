
WITH RankedSales AS (
    SELECT
        ss.sold_date_sk,
        ss.item_sk,
        ss.customer_sk,
        SUM(ss.net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.net_paid) DESC) AS sales_rank
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_holiday = 'Y')
    GROUP BY
        ss.sold_date_sk, ss.item_sk, ss.customer_sk
),
TopItems AS (
    SELECT
        item_sk,
        total_sales
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        t.total_sales,
        CASE
            WHEN i.i_current_price < 20 THEN 'Affordable'
            WHEN i.i_current_price BETWEEN 20 AND 100 THEN 'Moderate'
            ELSE 'Expensive'
        END AS price_category
    FROM
        item i
    JOIN TopItems t ON i.i_item_sk = t.item_sk
),
SalesAnalysis AS (
    SELECT
        ci.c_first_name,
        ci.c_last_name,
        id.i_item_desc,
        id.price_category,
        id.total_sales,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.item_sk = id.i_item_sk) AS sales_count
    FROM
        CustomerInfo ci
    JOIN ItemDetails id ON ci.c_customer_sk = (SELECT MIN(cu.c_customer_sk) FROM store_sales ss JOIN customer cu ON ss.customer_sk = cu.c_customer_sk WHERE ss.item_sk = id.i_item_sk)
)
SELECT
    sa.c_first_name,
    sa.c_last_name,
    sa.i_item_desc,
    sa.price_category,
    sa.total_sales,
    sa.sales_count,
    CASE
        WHEN sa.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM
    SalesAnalysis sa
WHERE
    sa.sales_count > (SELECT AVG(sales_count) FROM (SELECT COUNT(*) AS sales_count FROM store_sales GROUP BY customer_sk) AS avg_sales)
ORDER BY
    sa.total_sales DESC, sa.c_last_name ASC
LIMIT 50;
