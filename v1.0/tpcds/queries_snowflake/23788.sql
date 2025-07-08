
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq IN (1, 2)
        )
    GROUP BY 
        ws_item_sk
),
GroupedSales AS (
    SELECT 
        sd.ws_item_sk,
        CASE
            WHEN sd.total_sales IS NOT NULL AND sd.total_sales > 1000 THEN 'High Value'
            WHEN sd.total_sales IS NULL THEN 'Undefined Value'
            ELSE 'Low Value'
        END AS sales_category,
        sd.total_quantity,
        COALESCE(sd.total_sales, 0) AS net_sales,
        RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS net_sales_rank
    FROM 
        SalesData sd
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(gs.total_quantity, 0) AS total_sold_quantity,
        gs.sales_category
    FROM 
        item i
    LEFT JOIN 
        GroupedSales gs ON i.i_item_sk = gs.ws_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_product_name,
    id.i_current_price,
    id.total_sold_quantity,
    id.sales_category,
    CASE 
        WHEN id.sales_category = 'High Value' AND id.total_sold_quantity > 50 THEN 'Discount Eligible'
        ELSE 'Regular Price'
    END AS pricing_strategy,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_customer_sk IN (
         SELECT DISTINCT ws_bill_customer_sk 
         FROM web_sales 
         WHERE ws_item_sk = id.i_item_sk
     ) AND c_preferred_cust_flag = 'Y') AS preferred_customer_count
FROM 
    ItemDetails id
WHERE 
    id.sales_category IN ('High Value', 'Low Value')
ORDER BY 
    id.i_item_sk
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

