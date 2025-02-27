
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450122 AND 2450152
    GROUP BY 
        ws_item_sk
),
AdjustedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(sd.total_discounts, 0) AS adjusted_discounts,
        COALESCE(sd.total_quantity, 0) - COALESCE(sd.total_discounts, 0) AS net_sales_quantity,
        CASE 
            WHEN sd.total_sales > 10000 THEN 'High Performer'
            WHEN sd.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        SalesData sd
    LEFT JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
)
SELECT 
    a.ws_item_sk,
    i.i_item_desc,
    a.total_quantity,
    a.total_sales,
    a.adjusted_discounts,
    a.net_sales_quantity,
    a.performance_category,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM 
    AdjustedSales a
JOIN 
    item i ON a.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price IS NOT NULL 
    AND a.performance_category <> 'Low Performer'
    AND EXISTS (
        SELECT 
            1 
        FROM 
            store s 
        WHERE 
            s.s_store_sk = (SELECT sr_store_sk FROM store_returns WHERE sr_item_sk = a.ws_item_sk LIMIT 1)
    )
ORDER BY 
    a.total_sales DESC;
