
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
    AND 
        cd.cd_gender IS NOT NULL
),
WebSalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
StoreSalesData AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        COUNT(ss.ss_ticket_number) AS total_tickets,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_sold_date_sk, ss.ss_item_sk
),
ReturnData AS (
    SELECT 
        COALESCE(
            SUM(cr.cr_return_quantity), 
            0
        ) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amt,
        SUM(cr.cr_return_tax) AS total_return_tax
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 0
),
FinalSales AS (
    SELECT 
        wd.ws_sold_date_sk AS sales_date,
        wd.ws_item_sk,
        wd.total_sales,
        wd.total_quantity,
        sd.total_tickets,
        sd.avg_sales_price,
        rd.total_returns,
        rd.total_return_amt,
        rd.total_return_tax
    FROM 
        WebSalesData wd
    LEFT JOIN 
        StoreSalesData sd ON wd.ws_item_sk = sd.ss_item_sk
    LEFT JOIN 
        ReturnData rd ON rd.total_returns IS NOT NULL
    WHERE 
        wd.total_sales > 5000
    AND 
        COALESCE(sd.avg_sales_price, 0) < 200
)
SELECT 
    f.sales_date,
    f.ws_item_sk,
    SUM(f.total_sales) AS aggregated_sales,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    COUNT(f.total_quantity) OVER (PARTITION BY f.ws_item_sk) AS total_quantity_per_item,
    ROUND(AVG(f.avg_sales_price), 2) AS avg_price,
    CASE 
        WHEN f.total_returns > 100 THEN 'High Return'
        WHEN f.total_returns BETWEEN 50 AND 100 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    FinalSales f
JOIN 
    CustomerData c ON c.rn = 1
WHERE 
    c.cd_gender = 'M'
OR 
    c.cd_gender IS NULL
GROUP BY 
    f.sales_date, f.ws_item_sk, f.total_returns
HAVING 
    SUM(f.total_sales) IS NOT NULL
ORDER BY 
    f.sales_date DESC, aggregated_sales DESC;
