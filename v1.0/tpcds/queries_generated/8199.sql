
WITH SalesSummary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY cs_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
TopItems AS (
    SELECT 
        ss.cs_item_sk,
        ss.total_sales,
        dd.d_year,
        dd.d_month_seq
    FROM SalesSummary ss
    JOIN date_dim dd ON ss.total_orders > 10
    ORDER BY ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ti.cs_item_sk,
    ti.total_sales,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status
FROM TopItems ti
JOIN CustomerDetails cd ON cd.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk = ti.cs_item_sk
)
ORDER BY ti.total_sales DESC;
