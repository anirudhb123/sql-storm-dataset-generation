
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS returned_items,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.returned_items,
        cr.total_return_amt,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_store_sk
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cr.returned_items > 2
),
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MIN(ws_sold_date_sk) AS first_order_date,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        hrc.sr_customer_sk,
        sa.total_sales,
        sa.total_orders
    FROM 
        HighReturnCustomers hrc
    LEFT JOIN 
        SalesAnalysis sa ON hrc.sr_customer_sk = sa.ws_bill_customer_sk
)
SELECT 
    hrc.sr_customer_sk,
    hrc.returned_items,
    hrc.total_return_amt,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.total_orders, 0) AS total_orders,
    CASE 
        WHEN cs.total_sales > 0 THEN (hrc.total_return_amt / cs.total_sales) * 100 
        ELSE NULL 
    END AS return_percentage
FROM 
    HighReturnCustomers hrc
LEFT JOIN 
    CustomerSales cs ON hrc.sr_customer_sk = cs.sr_customer_sk
WHERE 
    hrc.cd_gender = 'F' 
    AND hrc.cd_marital_status = 'M'
ORDER BY 
    return_percentage DESC
LIMIT 10;
