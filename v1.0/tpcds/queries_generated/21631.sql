
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT 
        r.bill_customer_sk,
        r.total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 10
),
AggregateReturns AS (
    SELECT 
        cr.refunded_customer_sk,
        SUM(cr.return_amt) AS total_refunded_amount,
        COUNT(cr.return_quantity) AS total_returns,
        SUM(CASE WHEN cr.return_quantity IS NOT NULL THEN cr.return_quantity ELSE 0 END) AS non_null_return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.refunded_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_id,
        COALESCE(tc.total_net_profit, 0) AS total_net_profit,
        COALESCE(ar.total_refunded_amount, 0) AS total_refunded_amount,
        COALESCE(ar.total_returns, 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.bill_customer_sk
    LEFT JOIN 
        AggregateReturns ar ON c.c_customer_sk = ar.refunded_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating,
    CONCAT('Total Net Profit: $', FORMAT(c.total_net_profit, 2)) AS profit_summary,
    CONCAT('Total Refunded Amount: $', FORMAT(c.total_refunded_amount, 2)) AS refund_summary,
    CASE 
        WHEN c.total_returns > 0 THEN 'Returns Made' 
        ELSE 'No Returns' 
    END AS return_status
FROM 
    CombinedData c
JOIN 
    customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate) FROM customer_demographics
        WHERE cd_gender = 'M'
    )
ORDER BY 
    c.total_net_profit DESC, 
    cd.cd_gender;
