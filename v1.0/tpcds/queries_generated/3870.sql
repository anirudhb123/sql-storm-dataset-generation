
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
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
        cd.cd_credit_rating,
        c.c_email_address,
        COALESCE(cd.cd_dep_count, 0) AS dependency_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cu.*,
        cr.total_returned_quantity,
        cr.total_returns,
        RANK() OVER (ORDER BY cr.total_returned_quantity DESC) AS return_rank
    FROM CustomerDetails cu
    LEFT JOIN CustomerReturns cr ON cu.c_customer_sk = cr.sr_customer_sk
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.c_email_address,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_returned_quantity,
    tc.total_returns,
    CASE 
        WHEN tc.total_returned_quantity IS NULL THEN 'No Returns'
        ELSE 'Returned'
    END as return_status,
    COUNT(DISTINCT ws.web_site_sk) AS websites_used,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM TopCustomers tc
LEFT JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
WHERE tc.return_rank <= 10
GROUP BY 
    tc.c_first_name,
    tc.c_last_name,
    tc.c_email_address,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_returned_quantity,
    tc.total_returns
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_returned_quantity DESC;
