
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
ReturnRates AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COALESCE(CR.total_returns, 0) AS total_returns,
        CASE 
            WHEN COUNT(DISTINCT ws.order_number) > 0 THEN 
                (COALESCE(CR.total_returns, 0) * 1.0 / COUNT(DISTINCT ws.order_number)) 
            ELSE 0 
        END AS return_rate
    FROM web_sales ws
    LEFT JOIN CustomerReturns CR ON ws.bill_customer_sk = CR.sr_customer_sk
    GROUP BY ws.bill_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rr.total_orders,
        rr.total_returns,
        rr.return_rate,
        RANK() OVER (ORDER BY rr.return_rate DESC) AS rank
    FROM ReturnRates rr
    JOIN customer c ON rr.bill_customer_sk = c.c_customer_sk
    WHERE rr.return_rate > 0.5
)
SELECT 
    hrc.c_customer_id,
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.total_orders,
    hrc.total_returns,
    hrc.return_rate,
    CONCAT(hrc.c_first_name, ' ', hrc.c_last_name) AS full_name,
    CASE 
        WHEN hrc.return_rate > 0.75 THEN 'High Risk'
        WHEN hrc.return_rate BETWEEN 0.5 AND 0.75 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM HighReturnCustomers hrc
WHERE hrc.rank <= 10
ORDER BY hrc.return_rate DESC;
