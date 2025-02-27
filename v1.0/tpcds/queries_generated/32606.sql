
WITH RECURSIVE RecentSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        1 AS level
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    
    UNION ALL
    
    SELECT 
        cs.item_sk,
        cs.order_number,
        cs.sales_price,
        cs.quantity,
        level + 1
    FROM catalog_sales cs
    JOIN RecentSales rs ON cs.item_sk = rs.cs_item_sk AND cs.order_number < rs.cs_order_number
    WHERE level < 5
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        SUM(rs.cs_sales_price * rs.cs_quantity) AS total_sales,
        COUNT(rs.cs_order_number) AS order_count,
        item.i_category,
        item.i_brand,
        ROW_NUMBER() OVER (PARTITION BY item.i_category ORDER BY SUM(rs.cs_sales_price * rs.cs_quantity) DESC) AS category_rank
    FROM RecentSales rs
    JOIN item ON rs.cs_item_sk = item.i_item_sk
    GROUP BY item.i_item_id, item.i_category, item.i_brand
),
TopCategories AS (
    SELECT 
        i_category,
        MAX(total_sales) AS max_sales
    FROM SalesSummary
    WHERE order_count > 1
    GROUP BY i_category
)
SELECT 
    ss.i_item_id, 
    ss.total_sales,
    ss.order_count,
    ss.i_category,
    ss.i_brand
FROM SalesSummary ss
JOIN TopCategories tc ON ss.i_category = tc.i_category 
WHERE ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary) 
  AND ss.order_count >= (
        SELECT COUNT(*) FROM customer_demographics cd 
        WHERE cd.cd_marital_status = 'M' 
          AND cd.cd_dep_count > 0
    )
ORDER BY ss.total_sales DESC, ss.i_item_id
LIMIT 50;
