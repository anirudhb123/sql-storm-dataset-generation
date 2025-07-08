
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighPerformers AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM item i
    JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN customer c ON c.c_customer_sk = (
        SELECT MIN(ws_bill_customer_sk) 
        FROM web_sales 
        WHERE ws_item_sk = rs.ws_item_sk
    )
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE rs.sales_rank <= 10
),
SalesByGender AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales
    FROM HighPerformers
    GROUP BY cd_gender
)
SELECT 
    sbg.cd_gender,
    sbg.customer_count,
    sbg.total_sales,
    COALESCE(sbg.total_sales / NULLIF(SUM(sbg.total_sales) OVER (), 0), 0) AS sales_percentage
FROM SalesByGender sbg
ORDER BY sbg.total_sales DESC;
