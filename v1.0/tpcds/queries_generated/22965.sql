
WITH RankedReturns AS (
    SELECT 
        sr.refunded_cash,
        sr.returned_date_sk,
        sr.returning_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr.returning_customer_sk ORDER BY sr.returned_cash DESC) AS rn
    FROM 
        store_returns sr 
    WHERE 
        sr.return_quantity IS NOT NULL
),
CustomerRisk AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT rr.returning_customer_sk) AS return_count,
        AVG(COALESCE(sr.return_quantity, 0)) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns rr ON c.c_customer_sk = rr.returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighRiskCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.return_count,
        cr.avg_return_quantity,
        CASE 
            WHEN cr.return_count > 5 THEN 'High Risk'
            WHEN cr.avg_return_quantity > 10 THEN 'Moderate Risk'
            ELSE 'Low Risk'
        END AS risk_level
    FROM 
        CustomerRisk cr
),
SalesAsOfDate AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq <= 3)
    GROUP BY 
        ws.ws_sold_date_sk
),
CumulativeSales AS (
    SELECT 
        ws_sold_date_sk,
        SUM(total_sales_price) OVER (ORDER BY ws_sold_date_sk) AS cumulative_sales
    FROM 
        SalesAsOfDate
)
SELECT 
    c.c_customer_id,
    cr.return_count,
    cr.avg_return_quantity,
    hr.risk_level,
    cs.cumulative_sales
FROM 
    customer c
JOIN 
    HighRiskCustomers hr ON c.c_customer_sk = hr.c_customer_sk
LEFT JOIN 
    CumulativeSales cs ON cs.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
ORDER BY 
    cr.return_count DESC, c.c_customer_id;
