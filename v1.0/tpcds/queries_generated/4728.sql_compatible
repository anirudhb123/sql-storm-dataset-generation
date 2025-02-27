
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_returned_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ReturnAnalysis AS (
    SELECT 
        d.d_date,
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        cd.total_sales,
        CASE 
            WHEN COALESCE(cr.total_returned_quantity, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM date_dim d
    JOIN CustomerDetails cd ON cd.c_customer_sk = d.d_date_sk
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT 
    return_status,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_returned_amount) AS total_returned_amount,
    SUM(total_returned_quantity) AS total_returned_quantity
FROM ReturnAnalysis
GROUP BY return_status
ORDER BY return_status DESC;
