
WITH RecursiveCustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(sr_return_amt) AS average_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
CustomerDemographicsAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'LOW'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_estimate_category
    FROM 
        customer_demographics cd
    WHERE 
        EXISTS (
            SELECT 1 
            FROM customer c 
            WHERE c.c_customer_sk = cd.cd_demo_sk 
            AND c.c_first_name LIKE 'J%' 
            AND c.c_last_name IS NOT NULL
        )
),
SalesAnalysis AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(*) AS total_units_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk > 0
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
CustomerReturnMetrics AS (
    SELECT 
        c.c_customer_id,
        COALESCE(rc.return_count, 0) AS return_count,
        COALESCE(rc.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rc.average_return_amount, 0) AS average_return_amount,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_month,
        c.c_birth_day,
        CASE 
            WHEN c.c_birth_month IS NULL THEN 'UNKNOWN'
            ELSE TO_CHAR(TO_DATE(c.c_birth_month || '/' || c.c_birth_day || '/2000', 'MM/DD/YYYY'), 'Month DD') 
        END AS formatted_birthday
    FROM 
        customer c
    LEFT JOIN 
        RecursiveCustomerReturns rc ON c.c_customer_sk = rc.sr_customer_sk
),
SalesRanked AS (
    SELECT 
        ca.c_customer_id,
        SUM(sa.total_sales) AS grand_total_sales,
        RANK() OVER (ORDER BY SUM(sa.total_sales) DESC) AS sales_rank
    FROM 
        SalesAnalysis sa
    JOIN 
        CustomerReturnMetrics ca ON sa.ws_item_sk = ca.c_customer_id
    GROUP BY 
        ca.c_customer_id
)
SELECT 
    cr.c_customer_id,
    cr.return_count,
    cr.total_return_quantity,
    cr.average_return_amount,
    cr.c_first_name || ' ' || cr.c_last_name AS full_name,
    cr.formatted_birthday,
    COALESCE(sr.grand_total_sales, 0) AS grand_total_sales,
    sr.sales_rank
FROM 
    CustomerReturnMetrics cr
LEFT JOIN 
    SalesRanked sr ON cr.c_customer_id = sr.c_customer_id
WHERE 
    cr.average_return_amount > (SELECT AVG(average_return_amount) FROM RecursiveCustomerReturns)
    OR sr.sales_rank IS NULL
ORDER BY 
    cr.return_count DESC, 
    sr.grand_total_sales DESC;
