
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0
),
ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesReturns AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        SUM(ss_net_paid) AS total_sales,
        COALESCE(ir.total_returned, 0) AS total_returned,
        COALESCE(ir.total_return_amt, 0) AS total_return_amt,
        (SUM(ss_net_paid) - COALESCE(ir.total_return_amt, 0)) AS net_sale_adjusted
    FROM 
        store_sales ss
    LEFT JOIN 
        ItemReturns ir ON ss.ss_item_sk = ir.wr_item_sk
    GROUP BY 
        ss_item_sk
)
SELECT 
    s.s_store_name,
    i.i_item_id,
    COALESCE(sr.total_sold, 0) AS total_sold,
    COALESCE(sr.total_returned, 0) AS total_returned,
    COALESCE(sr.net_sale_adjusted, 0) AS net_sale_adjusted,
    CASE 
        WHEN COALESCE(sr.net_sale_adjusted, 0) > 0 THEN 'Positive Sales'
        WHEN COALESCE(sr.net_sale_adjusted, 0) < 0 THEN 'Negative Sales'
        ELSE 'No Sales'
    END AS sales_status,
    CASE 
        WHEN (SELECT COUNT(DISTINCT c.c_customer_sk) 
              FROM customer c 
              WHERE c.c_current_cdemo_sk IS NULL) = 0 THEN 'All Customers Have Demographics'
        ELSE 'Some Customers Lack Demographics'
    END AS customer_demographics_status
FROM 
    store s 
JOIN 
    SalesReturns sr ON sr.ss_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = sr.ss_item_sk LIMIT 1)
LEFT JOIN 
    item i ON i.i_item_sk = sr.ss_item_sk
WHERE 
    s.s_state = 'CA'
AND 
    COALESCE(sr.total_sold, 0) > 5
ORDER BY 
    net_sale_adjusted DESC;
