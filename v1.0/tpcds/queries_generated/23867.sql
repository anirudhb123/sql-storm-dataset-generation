
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank_net
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COUNT(DISTINCT RankedSales.ws_order_number) AS order_count,
        SUM(RankedSales.ws_sales_price) AS total_sales,
        AVG(RankedSales.ws_sales_price) AS avg_sales_price,
        MAX(RankedSales.ws_sales_price) AS max_sales_price,
        MIN(RankedSales.ws_sales_price) AS min_sales_price
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    COALESCE(ss.order_count, 0) AS order_count,
    CASE
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    CONCAT('Total Sales: $', CAST(ss.total_sales AS CHAR(10))) AS sales_info,
    pd.avg_discount,
    CASE 
        WHEN pd.avg_discount IS NOT NULL AND pd.avg_discount > 15 THEN 'Above Average Discount'
        ELSE 'Average Discount'
    END AS discount_info
FROM 
    SalesSummary ss
LEFT JOIN (
    SELECT 
        p.p_item_sk,
        AVG(p.p_cost) AS avg_discount
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_item_sk
) pd ON ss.i_item_id = pd.p_item_sk
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    ss.total_sales DESC 
LIMIT 100;
