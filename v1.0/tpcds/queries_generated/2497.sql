
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(sr_ticket_number) AS total_returns,
        AVG(sr_return_quantity) AS avg_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_web_returned_amount,
        COUNT(wr_order_number) AS total_web_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
ReturnSummary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returned_amount, 0) AS in_store_returned_amount,
        COALESCE(wr.total_web_returned_amount, 0) AS online_returned_amount,
        cr.total_returns AS in_store_total_returns,
        wr.total_web_returns AS online_total_returns
    FROM 
        customer c
        LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
        LEFT JOIN WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 5000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM 
        customer_demographics cd
)
SELECT 
    r.c_customer_id,
    r.in_store_returned_amount,
    r.online_returned_amount,
    r.in_store_total_returns,
    r.online_total_returns,
    d.cd_gender,
    d.cd_marital_status,
    d.purchase_category,
    COUNT(DISTINCT CASE 
        WHEN r.in_store_returned_amount > 0 THEN r.c_customer_id ELSE NULL 
    END) AS count_of_in_store_returners,
    COUNT(DISTINCT CASE 
        WHEN r.online_returned_amount > 0 THEN r.c_customer_id ELSE NULL 
    END) AS count_of_online_returners
FROM 
    ReturnSummary r
JOIN 
    CustomerDemographics d ON r.c_customer_id = d.cd_demo_sk
WHERE 
    (r.in_store_total_returns > 0 OR r.online_total_returns > 0)
    AND (d.cd_gender IS NOT NULL AND d.cd_marital_status IS NOT NULL)
GROUP BY 
    r.c_customer_id,
    r.in_store_returned_amount,
    r.online_returned_amount,
    r.in_store_total_returns,
    r.online_total_returns,
    d.cd_gender,
    d.cd_marital_status,
    d.purchase_category
HAVING 
    SUM(r.in_store_returned_amount + r.online_returned_amount) > 1000
ORDER BY 
    r.in_store_returned_amount DESC, r.online_returned_amount DESC;
