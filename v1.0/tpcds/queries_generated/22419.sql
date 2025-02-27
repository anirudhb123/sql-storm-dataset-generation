
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
PotentialIssues AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(cr.total_returned_amount, 0) AS total_returns,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(cr.return_count, 0) > 5 THEN 'High Risk'
            WHEN COALESCE(cr.return_count, 0) BETWEEN 1 AND 5 THEN 'Moderate Risk'
            ELSE 'Low Risk'
        END AS risk_category,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) < 100 THEN 'Underperformer'
            ELSE 'Performer'
        END AS performance_status
    FROM 
        customer c 
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cp.cp_catalog_page_id,
    MAX(pi.avg_return_quantity) OVER (PARTITION BY pi.risk_category) AS max_avg_return_quantity,
    SUM(pi.total_returns) AS total_returns,
    SUM(pi.total_sales) AS total_sales,
    STRING_AGG(CONCAT(pi.c_first_name, ' ', pi.c_last_name) ORDER BY pi.total_sales DESC) FILTER (WHERE pi.performance_status = 'Performer') AS performers,
    COUNT(DISTINCT pi.c_customer_id) FILTER (WHERE pi.performance_status = 'Underperformer') AS underperformer_count
FROM 
    catalog_page cp
JOIN 
    PotentialIssues pi ON cp.cp_catalog_page_id = CONCAT('CP-', RIGHT(pi.c_customer_id, 8))
GROUP BY 
    cp.cp_catalog_page_id
ORDER BY 
    total_sales DESC;
