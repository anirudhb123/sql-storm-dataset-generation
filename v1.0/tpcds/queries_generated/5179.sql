
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_item_sk
),
CustomerData AS (
    SELECT 
        c_current_cdemo_sk,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM customer
    GROUP BY c_current_cdemo_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sd.total_sales) AS total_sales
    FROM customer_demographics cd
    LEFT JOIN CustomerData c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
RankedDemographics AS (
    SELECT 
        d.*,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM Demographics d
)
SELECT 
    rd.cd_gender,
    rd.cd_marital_status,
    rd.cd_education_status,
    rd.customer_count,
    rd.total_sales,
    rd.sales_rank
FROM RankedDemographics rd
WHERE rd.sales_rank <= 10
ORDER BY rd.cd_gender, rd.sales_rank;
