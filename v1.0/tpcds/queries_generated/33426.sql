
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) + (SELECT total_quantity FROM SalesCTE WHERE ws_item_sk = cs_item_sk) AS total_quantity,
        SUM(cs_sales_price) + (SELECT total_sales FROM SalesCTE WHERE ws_item_sk = cs_item_sk) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
CustomerReturns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
SalesAndReturns AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS total_sales_quantity,
        COALESCE(s.total_sales, 0) AS total_sales_amount,
        COALESCE(r.total_returned, 0) AS total_returned_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM 
        SalesCTE s
    FULL OUTER JOIN 
        CustomerReturns r ON s.ws_item_sk = r.cr_item_sk
),
FinalResults AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_sales_quantity,
        sa.total_sales_amount,
        sa.total_returned_quantity,
        sa.total_return_amount,
        (sa.total_sales_amount - sa.total_return_amount) AS net_sales_amount,
        CASE 
            WHEN sa.total_sales_quantity > 0 THEN 
                (sa.total_returned_quantity::decimal / sa.total_sales_quantity) * 100 
            ELSE 0 
        END AS return_rate
    FROM 
        SalesAndReturns sa
    WHERE 
        sa.total_sales_amount > 1000 AND 
        (sa.total_sales_quantity - sa.total_returned_quantity) > 0
)
SELECT 
    COUNT(*) AS total_items,
    AVG(return_rate) AS average_return_rate,
    SUM(net_sales_amount) AS total_net_sales
FROM 
    FinalResults
WHERE 
    return_rate < 20
ORDER BY 
    total_net_sales DESC;
