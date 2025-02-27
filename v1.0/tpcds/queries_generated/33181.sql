
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        s.ss_sold_date_sk, 
        s.ss_item_sk, 
        SUM(s.ss_ext_sales_price) 
    FROM 
        store_sales s
    JOIN 
        Sales_CTE sc ON s.ss_sold_date_sk = sc.ws_sold_date_sk AND s.ss_item_sk = sc.ws_item_sk 
    GROUP BY 
        s.ss_sold_date_sk, 
        s.ss_item_sk
),
Negative_Returns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
Sales_With_Returns AS (
    SELECT 
        COALESCE(sc.ws_item_sk, nr.cr_item_sk) AS item_sk, 
        COALESCE(sc.total_sales, 0) AS total_sales, 
        COALESCE(nr.total_return_amount, 0) AS total_returns,
        (COALESCE(sc.total_sales, 0) - COALESCE(nr.total_return_amount, 0)) AS net_sales 
    FROM 
        Sales_CTE sc
    FULL OUTER JOIN 
        Negative_Returns nr ON sc.ws_item_sk = nr.cr_item_sk
),
Ranked_Sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
    FROM 
        Sales_With_Returns
)
SELECT 
    ws_item_sk, 
    total_sales, 
    total_returns, 
    net_sales, 
    sales_rank
FROM 
    Ranked_Sales
WHERE 
    net_sales > 0
AND 
    (total_sales IS NOT NULL OR total_returns IS NOT NULL)
ORDER BY 
    net_sales DESC
LIMIT 50;
