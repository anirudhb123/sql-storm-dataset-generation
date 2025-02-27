
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        COUNT(cr_returning_customer_sk) AS ReturnCount,
        SUM(cr_return_amount) AS TotalReturnAmount,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY COUNT(cr_returning_customer_sk) DESC) AS rn
    FROM 
        catalog_returns
    WHERE 
        cr_item_sk IN (SELECT wr_item_sk FROM web_returns WHERE wr_return_quantity > 0)
    GROUP BY 
        cr_returning_customer_sk
),
TopReturners AS (
    SELECT 
        cr_returning_customer_sk, 
        ReturnCount, 
        TotalReturnAmount
    FROM 
        RankedReturns
    WHERE 
        rn <= 10
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnImpact AS (
    SELECT 
        s.ws_bill_customer_sk,
        COALESCE(r.ReturnCount, 0) AS ReturnCount,
        COALESCE(r.TotalReturnAmount, 0) AS TotalReturnAmount,
        s.TotalSales,
        (s.TotalSales - COALESCE(r.TotalReturnAmount, 0)) AS NetSales
    FROM 
        SalesData s
    LEFT JOIN 
        TopReturners r ON s.ws_bill_customer_sk = r.cr_returning_customer_sk
)
SELECT 
    w.warehouse_id, 
    c.c_first_name, 
    c.c_last_name, 
    ri.ReturnCount, 
    ri.TotalReturnAmount, 
    ri.NetSales,
    CASE 
        WHEN ri.NetSales < 0 THEN 'Loss'
        WHEN ri.NetSales BETWEEN 0 AND 5000 THEN 'Low'
        WHEN ri.NetSales BETWEEN 5001 AND 10000 THEN 'Medium'
        ELSE 'High' 
    END AS SalesCategory
FROM 
    ReturnImpact ri
JOIN 
    customer c ON ri.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    warehouse w ON c.c_current_addr_sk = w.w_warehouse_sk
WHERE 
    w.w_warehouse_id LIKE 'WH%'
AND 
    (c.c_birth_month IS NOT NULL OR c.c_birth_year IS NOT NULL)
ORDER BY 
    ri.NetSales DESC
LIMIT 50;
