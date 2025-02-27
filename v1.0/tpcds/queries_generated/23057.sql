
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ss_store_sk, ss_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price,
        DENSE_RANK() OVER (ORDER BY rs.total_sales DESC) AS item_rank
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ss_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 5
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year IS NOT NULL
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    tsi.ss_store_sk,
    tsi.i_item_desc,
    tsi.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.avg_purchase_estimate,
    CASE
        WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'S' THEN 'Single Male'
        WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'S' THEN 'Single Female'
        ELSE 'Other'
    END AS demographic_group
FROM
    TopSellingItems tsi
LEFT JOIN
    CustomerDemographics cd ON tsi.ss_store_sk = cd.cd_demo_sk OR cd.customer_count IS NULL
ORDER BY
    tsi.total_sales DESC, cd.customer_count DESC
LIMIT 10;
