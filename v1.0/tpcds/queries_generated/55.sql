
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk 
                               FROM date_dim 
                               WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3)
    GROUP BY ws_item_sk
),
TopSellingItems AS (
    SELECT
        i.i_item_id,
        s.total_quantity,
        s.total_sales,
        s.order_count,
        ROW_NUMBER() OVER (PARTITION BY s.total_quantity ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesData s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    WHERE s.total_quantity > 100
),
CustomerGenderDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year < 1990
    GROUP BY cd.cd_gender
),
ItemSalesRank AS (
    SELECT 
        item_id,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM TopSellingItems
    WHERE sales_rank <= 10
)
SELECT 
    i.item_id,
    coalesce(g.customer_count, 0) AS customer_count,
    i.total_quantity,
    i.total_sales,
    CASE 
        WHEN i.total_sales > 5000 THEN 'High Seller'
        WHEN i.total_sales > 2000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS sale_category,
    g.cd_gender
FROM ItemSalesRank i
LEFT JOIN CustomerGenderDemographics g ON i.item_id = g.cd_gender
WHERE i.total_quantity > (
    SELECT AVG(total_quantity) 
    FROM SalesData
)
ORDER BY i.total_sales DESC;
