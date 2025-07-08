
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS total_returns,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM
        store_returns
    WHERE
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 90 FROM date_dim)
    GROUP BY
        sr_customer_sk
),
TopCustomers AS (
    SELECT
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cc.cc_name,
        cr.total_return_amount,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM
        CustomerReturns cr
    JOIN
        customer_demographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    LEFT JOIN
        call_center cc ON cc.cc_call_center_sk = (
            SELECT
                cc_call_center_sk
            FROM
                store s
            JOIN
                store_sales ss ON ss.ss_store_sk = s.s_store_sk
            WHERE
                ss.ss_customer_sk = cr.sr_customer_sk
            LIMIT 1
        )
),
FilterResults AS (
    SELECT 
        tc.sr_customer_sk,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_purchase_estimate,
        tc.cc_name,
        tc.total_return_amount,
        tc.return_rank,
        CASE
            WHEN tc.cd_gender = 'M' AND tc.cd_marital_status = 'M' THEN 'Married Male'
            WHEN tc.cd_gender = 'M' AND tc.cd_marital_status = 'S' THEN 'Single Male'
            WHEN tc.cd_gender = 'F' AND tc.cd_marital_status = 'M' THEN 'Married Female'
            WHEN tc.cd_gender = 'F' AND tc.cd_marital_status = 'S' THEN 'Single Female'
            ELSE 'Other'
        END AS customer_segment
    FROM 
        TopCustomers tc
    WHERE 
        tc.return_rank <= 10
)
SELECT 
    fr.customer_segment,
    COUNT(*) AS count_customers,
    AVG(fr.total_return_amount) AS avg_return_amount,
    SUM(fr.total_return_amount) AS total_return_amount,
    LISTAGG(fr.cc_name, ', ') AS call_centers
FROM 
    FilterResults fr
GROUP BY 
    fr.customer_segment
ORDER BY 
    total_return_amount DESC;
