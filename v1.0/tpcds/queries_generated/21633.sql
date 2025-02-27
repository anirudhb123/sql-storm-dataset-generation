
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        rcs.c_customer_id,
        rcs.total_sales,
        rcs.order_count,
        COALESCE(cd.cd_gender, 'U') AS gender,
        CASE 
            WHEN rcs.total_sales > 1000 THEN 'High Value'
            WHEN rcs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        RankedSales rcs
    LEFT JOIN 
        customer_demographics cd ON rcs.c_customer_id = cd.cd_demo_sk
    WHERE 
        rank = 1
),
SalesReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_id,
        hvc.total_sales,
        hvc.order_count,
        hvc.gender,
        hvc.customer_value,
        COALESCE(SUM(sr.total_returns), 0) AS total_returns
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        SalesReturns sr ON hvc.c_customer_id = sr.sr_item_sk
    GROUP BY 
        hvc.c_customer_id, hvc.total_sales, hvc.order_count, hvc.gender, hvc.customer_value
)
SELECT 
    f.*,
    CASE 
        WHEN f.total_returns > 0 THEN 'Returned'
        WHEN f.total_sales IS NULL THEN 'No Sales'
        ELSE 'Active'
    END AS sales_status
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC, f.customer_id;
