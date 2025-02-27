
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RecentTransactions AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerOverview AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(rt.total_sales, 0) AS total_recent_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_id = cr.c_customer_id
    LEFT JOIN 
        RecentTransactions rt ON c.c_customer_sk = rt.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cr.return_count, rt.total_sales
)
SELECT 
    co.c_customer_id,
    co.c_first_name,
    co.c_last_name,
    co.gender,
    co.avg_purchase_estimate,
    co.return_count,
    co.total_recent_sales,
    CASE 
        WHEN co.total_recent_sales > 1000 THEN 'High Value Customer'
        WHEN co.total_recent_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_category
FROM 
    CustomerOverview co
WHERE 
    co.avg_purchase_estimate IS NOT NULL 
    AND co.return_count < 5
ORDER BY 
    co.total_recent_sales DESC
LIMIT 100;
