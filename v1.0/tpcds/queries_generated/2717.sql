
WITH TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk AS customer_sk,
        SUM(sr_return_amt) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr_returning_customer_sk
),
CombinedData AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent,
        COALESCE(cr.total_returns, 0) AS total_returns,
        tc.spend_rank
    FROM 
        TopCustomers tc
    LEFT JOIN 
        CustomerReturns cr ON tc.c_customer_sk = cr.customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.total_spent,
    cd.total_returns,
    (cd.total_spent - cd.total_returns) AS net_spent,
    CASE 
        WHEN cd.total_spent IS NULL THEN 'No Spending'
        WHEN cd.spend_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    CombinedData cd
WHERE 
    (cd.net_spent > 100 OR cd.spend_rank <= 10)
ORDER BY 
    cd.total_spent DESC;

