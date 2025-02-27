
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales 
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
    HAVING 
        SUM(ss_net_paid) > 100
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        total_sales * 1.05 AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY total_sales * 1.05 DESC) AS sales_rank
    FROM 
        SalesCTE 
    WHERE 
        sales_rank <= 10
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
),
SalesRanks AS (
    SELECT 
        ss_item_sk,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS item_sales_rank
    FROM 
        SalesCTE
    WHERE 
        ss_item_sk IS NOT NULL
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    COALESCE(SR.total_sales, 0) AS total_sales,
    COALESCE(RS.total_returns, 0) AS total_returns,
    COALESCE(RS.total_return_amount, 0) AS total_return_amount,
    COALESCE(RS.total_return_tax, 0) AS total_return_tax,
    RANK() OVER (ORDER BY COALESCE(SR.total_sales, 0) - COALESCE(RS.total_return_amount, 0) DESC) AS overall_rank
FROM 
    item 
LEFT JOIN 
    (SELECT 
         ss_item_sk,
         SUM(ss_net_paid) AS total_sales 
     FROM 
         store_sales 
     GROUP BY 
         ss_item_sk) AS SR ON item.i_item_sk = SR.ss_item_sk
LEFT JOIN 
    ReturnStats RS ON item.i_item_sk = RS.wr_item_sk
WHERE 
    (COALESCE(SR.total_sales, 0) > 1000 OR COALESCE(RS.total_returns, 0) > 5)
ORDER BY 
    overall_rank
LIMIT 50;
