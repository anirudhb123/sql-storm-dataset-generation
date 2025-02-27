
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 0
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        cr.total_returns,
        cr.return_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND (cd.cd_purchase_estimate IS NULL OR cd.cd_purchase_estimate >= 5000)
    ORDER BY 
        cr.total_returns DESC
    LIMIT 10
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    tc.ca_state,
    ss.total_spent,
    ss.order_count,
    COALESCE((SELECT AVG(total_spent) FROM SalesSummary ss2 WHERE ss2.ws_bill_customer_sk = tc.c_customer_sk), 0) AS avg_spent,
    CASE 
        WHEN ss.total_spent > COALESCE((SELECT AVG(total_spent) FROM SalesSummary), 0) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY 
    total_spent DESC;
