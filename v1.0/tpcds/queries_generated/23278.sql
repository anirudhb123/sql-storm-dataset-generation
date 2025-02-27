
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_return_amt_inc_tax) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
ItemReturnStats AS (
    SELECT 
        ir.cr_item_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0.0) AS total_return_amount,
        CASE 
            WHEN COALESCE(cr.total_return_amount, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        (SELECT DISTINCT cr_item_sk FROM catalog_returns) ir
    LEFT JOIN 
        CustomerReturns cr ON ir.cr_item_sk = cr.cr_returning_customer_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cp.total_spent,
    ir.return_status,
    COUNT(DISTINCT ir.cr_item_sk) AS distinct_items_returned
FROM 
    CustomerPurchases cp
JOIN 
    customer c ON cp.c_customer_sk = c.c_customer_sk
JOIN 
    ItemReturnStats ir ON ir.cr_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
GROUP BY 
    c.c_customer_id, cp.total_spent, ir.return_status
HAVING 
    (return_status = 'Returned' AND total_spent > 100) OR 
    (return_status = 'Not Returned' AND total_spent < 50);
