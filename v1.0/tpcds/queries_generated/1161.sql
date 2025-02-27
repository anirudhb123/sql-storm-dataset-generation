
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2451000 AND ws_sold_date_sk <= 2451050
    GROUP BY 
        ws_item_sk
),
SalesSummary AS (
    SELECT 
        ri.ws_item_sk,
        ISNULL(ci.i_item_desc, 'Unknown Item') AS item_desc,
        ri.total_quantity,
        ri.total_sales,
        CASE 
            WHEN ri.sales_rank = 1 THEN 'Top Seller'
            WHEN ri.sales_rank <= 5 THEN 'Best Sellers'
            ELSE 'Regular'
        END AS seller_category
    FROM 
        RankedSales ri
    LEFT JOIN 
        item ci ON ri.ws_item_sk = ci.i_item_sk
    WHERE 
        ri.total_quantity > 100
)
SELECT 
    ss.item_desc,
    ss.total_quantity,
    FORMAT(ss.total_sales, 'C', 'en-US') AS formatted_sales,
    ss.seller_category,
    COALESCE(ROUND(SUM(sr_return_quantity), 2), 0) AS total_returns,
    COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_value
FROM 
    SalesSummary ss
LEFT JOIN 
    store_returns sr ON ss.ws_item_sk = sr.sr_item_sk 
GROUP BY 
    ss.item_desc, 
    ss.total_quantity, 
    ss.total_sales, 
    ss.seller_category
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
