
WITH RankedSales AS (
    SELECT
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- last 30 days of a sample period
    GROUP BY
        cs_item_sk
),
TopItems AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_sales,
        RankedSales.order_count
    FROM
        RankedSales
    JOIN
        item ON RankedSales.cs_item_sk = item.i_item_sk
    WHERE
        RankedSales.sales_rank <= 10
),
CustomerSummary AS (
    SELECT
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_demo_sk
)
SELECT
    TopItems.i_item_id,
    TopItems.i_item_desc,
    TopItems.total_sales,
    TopItems.order_count,
    CustomerSummary.customer_count,
    CustomerSummary.avg_purchase_estimate,
    CustomerSummary.female_count,
    CustomerSummary.male_count
FROM
    TopItems
JOIN
    CustomerSummary ON TopItems.total_sales > (SELECT AVG(total_sales) FROM TopItems) 
ORDER BY
    TopItems.total_sales DESC;
