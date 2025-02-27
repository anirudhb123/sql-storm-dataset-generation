
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        i.i_category,
        DATE(d.d_date) AS SaleDate
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
SalesSummary AS (
    SELECT 
        sd.i_category,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS TotalSales,
        COUNT(sd.ws_quantity) AS TotalTransactions
    FROM 
        SalesData sd
    GROUP BY 
        sd.i_category
),
HighValueReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS TotalReturned,
        SUM(sr_return_amt) AS TotalReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
QualifiedReturns AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.TotalReturned, 
        hvc.TotalReturnAmt,
        rc.PurchaseRank
    FROM 
        HighValueReturns hvc
    JOIN 
        RankedCustomers rc ON hvc.sr_returning_customer_sk = rc.c_customer_sk
    WHERE 
        rc.PurchaseRank <= 10
)
SELECT 
    q.c_customer_sk,
    q.TotalReturned,
    q.TotalReturnAmt,
    cs.TotalSales,
    cs.TotalTransactions,
    COALESCE(cs.TotalSales / NULLIF(q.TotalReturned, 0), 0) AS SalesPerReturn
FROM 
    QualifiedReturns q
LEFT JOIN 
    SalesSummary cs ON cs.i_category = (SELECT i.i_category FROM item i WHERE i.i_item_sk = q.TotalReturned LIMIT 1)
ORDER BY 
    q.TotalReturned DESC;
