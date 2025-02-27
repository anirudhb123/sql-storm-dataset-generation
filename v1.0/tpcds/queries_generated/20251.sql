
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returned_quantity,
        SUM(wr.return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.order_number) AS total_return_orders,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY SUM(wr.return_quantity) DESC) AS rank
    FROM web_returns wr
    JOIN customer c ON wr.returning_customer_sk = c.c_customer_sk
    WHERE wr.return_quantity IS NOT NULL AND wr.return_amt IS NOT NULL
    GROUP BY wr.returning_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sales_price > 0 OR ws.ws_sales_price IS NULL
    GROUP BY ws.ws_bill_customer_sk
),
CustomerMetrics AS (
    SELECT 
        cs.returning_customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
        CASE 
            WHEN COALESCE(sd.total_sales_amt, 0) = 0 THEN NULL 
            ELSE (COALESCE(cr.total_return_amt, 0) / NULLIF(sd.total_sales_amt, 0)) * 100 
        END AS return_percentage
    FROM CustomerReturns cr 
    FULL OUTER JOIN SalesData sd ON cr.returning_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    cm.total_returned_quantity,
    cm.total_sales_quantity,
    cm.total_returned_amt,
    cm.total_sales_amt,
    cm.return_percentage,
    ROW_NUMBER() OVER (ORDER BY cm.return_percentage DESC NULLS LAST) AS customer_rank
FROM CustomerMetrics cm
JOIN customer c ON cm.returning_customer_sk = c.c_customer_sk
WHERE cm.return_percentage IS NOT NULL
  AND EXISTS (
      SELECT 1 
      FROM customer_demographics cd 
      WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate BETWEEN 100 AND 500
  )
ORDER BY customer_rank;
