
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_demo_sk,
        cd.cd_gender,
        COALESCE(NULLIF(cd.cd_marital_status, ''), 'N/A') AS marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS birth_order
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month = 12
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 500
),
RecentReturns AS (
    SELECT 
        sr.customer_sk,
        COUNT(sr.sr_item_sk) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.customer_sk
    HAVING 
        COUNT(sr.sr_item_sk) > 0
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.marital_status,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(rr.return_count, 0) AS return_count,
    COALESCE(rr.total_returned, 0) AS total_returned,
    CASE 
        WHEN ch.birth_order = 1 THEN 'Youngest'
        ELSE 'Older'
    END AS age_group
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    TopCustomers tc ON ch.c_customer_sk = tc.c_customer_sk
LEFT JOIN 
    RecentReturns rr ON ch.c_customer_sk = rr.customer_sk
WHERE 
    ch.cd_gender = 'F' AND 
    (ch.c_birth_year >= 1990 OR rr.return_count > 5)
ORDER BY 
    total_spent DESC, 
    ch.c_last_name;
