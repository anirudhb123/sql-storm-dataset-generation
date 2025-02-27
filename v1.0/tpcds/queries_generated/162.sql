
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        CASE 
            WHEN cd_income_band_sk IS NOT NULL THEN 'High Value'
            ELSE 'Standard'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.total_quantity,
    r.total_revenue,
    h.customer_value,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN h.customer_value = 'High Value' AND COALESCE(cr.return_count, 0) > 5 THEN 'Flagged'
        ELSE 'Normal'
    END AS customer_status
FROM 
    customer c
LEFT JOIN RankedSales r ON c.c_customer_sk = r.ws_item_sk
LEFT JOIN HighValueCustomers h ON c.c_customer_sk = h.c_customer_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    r.rank = 1
    AND h.customer_value IS NOT NULL
ORDER BY 
    r.total_revenue DESC
LIMIT 100;
