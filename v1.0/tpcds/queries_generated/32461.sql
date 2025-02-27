
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_sales_price
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND cs_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023))
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        SUM(s.ws_quantity) AS total_web_quantity,
        SUM(s.cs_quantity) AS total_catalog_quantity,
        (SUM(s.ws_quantity * s.ws_sales_price) + SUM(s.cs_quantity * s.cs_sales_price)) AS total_revenue
    FROM SalesCTE s
    JOIN item ON item.i_item_sk = s.ws_item_sk OR item.i_item_sk = s.cs_item_sk
    GROUP BY item.i_item_id
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_tax) AS total_web_return_tax
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        COALESCE(ss.total_web_quantity, 0) AS total_web_quantity,
        COALESCE(ss.total_catalog_quantity, 0) AS total_catalog_quantity,
        COALESCE(ss.total_revenue, 0) AS total_revenue,
        COALESCE(cr.total_web_returns, 0) AS total_web_returns,
        COALESCE(cr.total_web_return_amount, 0) AS total_web_return_amount,
        COALESCE(cr.total_web_return_tax, 0) AS total_web_return_tax
    FROM customer c
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.i_item_id
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
)
SELECT 
    f.c_customer_id,
    f.total_web_quantity,
    f.total_catalog_quantity,
    f.total_revenue,
    f.total_web_returns,
    f.total_web_return_amount,
    f.total_web_return_tax
FROM FinalReport f
WHERE (f.total_web_quantity + f.total_catalog_quantity) > 0
ORDER BY total_revenue DESC
LIMIT 100;
