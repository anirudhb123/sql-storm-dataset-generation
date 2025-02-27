
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit, 
        1 AS level
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales) 
    
    UNION ALL
    
    SELECT 
        cs_order_number, 
        cs_item_sk, 
        cs_quantity, 
        cs_net_profit, 
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IN (SELECT ws_item_sk FROM SalesCTE WHERE level = 1)
),
CustomerSales AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
),
ReturnSummary AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
FinalSales AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales,
        cs.order_count,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.return_count, 0) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnSummary rs ON cs.c_customer_sk = rs.cr_returning_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.total_sales,
    f.order_count,
    f.total_return_amount,
    f.return_count,
    f.sales_rank,
    CASE 
        WHEN f.total_sales > 1000 THEN 'High Value'
        WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    FinalSales f
WHERE 
    f.sales_rank <= 10
ORDER BY 
    f.total_sales DESC;
