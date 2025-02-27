
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ss_ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        AVG(ss_ext_discount_amt) AS avg_discount,
        SUM(ss_quantity) AS total_units_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2022
    GROUP BY d.d_year
),
ItemSummary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
    HAVING total_quantity_sold > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.unique_customers,
    ss.avg_discount,
    ss.total_units_sold,
    is.avg_sales_price,
    is.total_quantity_sold,
    cd.cd_gender,
    cd.customer_count,
    cd.avg_purchase_estimate
FROM SalesSummary ss
JOIN ItemSummary is ON ss.total_sales > 10000
JOIN CustomerDemographics cd ON cd.avg_purchase_estimate > 5000
ORDER BY ss.d_year, cd.cd_gender;
