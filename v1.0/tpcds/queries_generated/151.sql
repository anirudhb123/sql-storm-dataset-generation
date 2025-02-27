
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
)

SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_store_returns,
    coalesce(wss.total_orders, 0) AS total_web_orders,
    coalesce(wss.total_net_paid_inc_tax, 0) AS total_web_spending,
    CASE 
        WHEN cr.total_store_returns > 0 THEN 'Returns'
        ELSE 'No Returns'
    END AS return_status
FROM 
    CustomerReturns cr
LEFT JOIN 
    WebSalesSummary wss ON cr.c_customer_sk = wss.ws_bill_customer_sk
JOIN 
    CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk_sk
WHERE 
    (cd.cd_gender = 'F' AND cr.total_net_loss > 100) OR 
    (cd.cd_gender = 'M' AND cr.total_store_returns > 5)
ORDER BY 
    cr.total_store_returns DESC, 
    wss.total_web_spending DESC
LIMIT 100;

