
WITH RECURSIVE Recent_Sales AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_sold_date_sk DESC) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
Sales_Aggregate AS (
    SELECT 
        rs.cs_item_sk,
        SUM(rs.cs_sales_price) AS total_sales,
        COUNT(DISTINCT rs.cs_order_number) AS order_count
    FROM Recent_Sales rs
    WHERE rs.rn = 1
    GROUP BY rs.cs_item_sk
),
Customer_Segment AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_segment
    FROM customer_demographics cd
),
Item_Sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        sa.total_sales,
        cs.purchase_segment
    FROM Sales_Aggregate sa
    JOIN item i ON sa.cs_item_sk = i.i_item_sk
    LEFT JOIN Customer_Segment cs ON cs.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_customer_sk IN (SELECT DISTINCT cs.bill_customer_sk FROM catalog_sales cs)
        LIMIT 1
    )
)
SELECT 
    its.i_item_id,
    its.i_item_desc,
    its.total_sales,
    COALESCE(its.purchase_segment, 'Unknown') AS purchase_segment
FROM Item_Sales its
WHERE its.total_sales > (SELECT AVG(total_sales) FROM Sales_Aggregate)
ORDER BY its.total_sales DESC
LIMIT 10;
