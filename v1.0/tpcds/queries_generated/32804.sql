
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as rn
    FROM 
        web_sales
    WHERE 
        ws_bill_customer_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesSummary AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_sales_price) AS total_sales_price,
        SUM(s.ws_net_paid) AS total_net_paid,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        COALESCE(r.total_return_tax, 0) AS total_return_tax
    FROM 
        SalesData s
    LEFT JOIN 
        CustomerReturns r ON s.ws_item_sk = r.wr_item_sk
    GROUP BY 
        s.ws_item_sk
)
SELECT 
    si.i_item_id,
    i.i_product_name,
    ss.total_sales_price,
    ss.total_net_paid,
    ss.total_returns,
    ss.total_return_amt,
    ss.total_return_tax,
    CASE 
        WHEN ss.total_sales_price > 1000 THEN 'High Performer'
        WHEN ss.total_sales_price BETWEEN 500 AND 1000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    SalesSummary ss
JOIN 
    item si ON ss.ws_item_sk = si.i_item_sk
WHERE 
    ss.total_net_paid > 0 
    AND (
        EXIST (SELECT 1 
               FROM catalog_sales cs 
               WHERE cs.cs_item_sk = ss.ws_item_sk AND cs.cs_net_profit < 0)
    )
    AND ss.total_returns < 10
ORDER BY 
    total_sales_price DESC, total_net_paid DESC
LIMIT 100;
