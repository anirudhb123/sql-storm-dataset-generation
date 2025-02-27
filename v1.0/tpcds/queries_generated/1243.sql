
WITH SalesAggregates AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
PopularItems AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity,
        ci.cd_gender,
        ci.cd_marital_status
    FROM 
        SalesAggregates sa
    JOIN 
        CustomerInfo ci ON sa.ws_item_sk IN (
            SELECT cr_item_sk
            FROM catalog_returns
            WHERE cr_returned_date_sk IN (
                SELECT d_date_sk 
                FROM date_dim 
                WHERE d_year = 2023
            )
        )
    WHERE 
        sales_rank <= 10
),
FinalReport AS (
    SELECT 
        pi.ws_item_sk,
        pi.total_quantity,
        pi.cd_gender,
        pi.cd_marital_status,
        CASE 
            WHEN pi.cd_marital_status = 'M' THEN 'Married'
            WHEN pi.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status_label
    FROM 
        PopularItems pi
)

SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.cd_gender,
    fr.marital_status_label,
    COUNT(DISTINCT fr.cd_gender) OVER (PARTITION BY fr.marital_status_label) AS gender_count,
    SUM(fr.total_quantity) OVER (PARTITION BY fr.marital_status_label) AS quantity_per_marital_status
FROM 
    FinalReport fr
ORDER BY 
    quantity_per_marital_status DESC, 
    fr.ws_item_sk;
