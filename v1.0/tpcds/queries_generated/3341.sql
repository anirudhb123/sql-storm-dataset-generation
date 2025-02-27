
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.sold_date_sk BETWEEN 2400 AND 2420
        AND c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.bill_customer_sk, ws.ship_customer_sk
),
customer_demos AS (
    SELECT 
        cd.cd_demo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.purchase_estimate > 1000
),
return_details AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_return_qty,
        SUM(wr.return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
top_customers AS (
    SELECT 
        r.bill_customer_sk,
        COALESCE(d.gender, 'Unknown') AS customer_gender,
        COALESCE(d.marital_status, 'Unknown') AS marital_status,
        r.total_quantity,
        r.total_sales,
        COALESCE(ret.total_return_qty, 0) AS total_return_qty,
        COALESCE(ret.total_return_amt, 0) AS total_return_amt
    FROM 
        ranked_sales r
    LEFT JOIN 
        customer_demos d ON r.bill_customer_sk = d.cd_demo_sk
    LEFT JOIN 
        return_details ret ON r.bill_customer_sk = ret.returning_customer_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    tc.customer_gender,
    tc.marital_status,
    COUNT(tc.bill_customer_sk) AS customer_count,
    SUM(tc.total_sales) AS total_sales,
    SUM(tc.total_return_qty) AS total_return_qty,
    SUM(tc.total_return_amt) AS total_return_amt,
    CASE 
        WHEN SUM(tc.total_sales) IS NULL THEN 'No Sales'
        WHEN SUM(tc.total_sales) > 0 AND SUM(tc.total_return_qty) > 0 THEN 'Mixed Outcomes'
        WHEN SUM(tc.total_sales) > 0 THEN 'Positive Outcome'
        ELSE 'Negative Outcome'
    END AS sales_outcome
FROM 
    top_customers tc
GROUP BY 
    tc.customer_gender, 
    tc.marital_status
ORDER BY 
    total_sales DESC;
