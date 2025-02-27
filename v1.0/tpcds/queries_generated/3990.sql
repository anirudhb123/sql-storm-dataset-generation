
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_amount,
        DENSE_RANK() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) as return_rank
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
CustomerStats AS (
    SELECT 
        c.customer_sk,
        cd.gender,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amount) AS total_returned_amount,
        AVG(sr.return_amount) AS avg_returned_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN 
        RankedReturns sr ON c.customer_sk = sr.customer_sk
    GROUP BY 
        c.customer_sk, cd.gender
),
DailySales AS (
    SELECT 
        d.d_date_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.sold_date_sk
    GROUP BY 
        d.d_date_sk
),
ReturnSalesComparison AS (
    SELECT 
        cs.customer_sk,
        cs.total_returns,
        ds.total_sales,
        ds.total_orders,
        CASE 
            WHEN ds.total_sales IS NULL THEN 0 
            ELSE (cs.total_returns::decimal / ds.total_sales) * 100 
        END AS return_rate_percentage
    FROM 
        CustomerStats cs
    LEFT JOIN 
        DailySales ds ON cs.customer_sk = ds.total_orders
)
SELECT 
    rsc.customer_sk,
    rsc.total_returns,
    rsc.total_sales,
    rsc.return_rate_percentage,
    CASE 
        WHEN rsc.return_rate_percentage > 20 THEN 'High'
        WHEN rsc.return_rate_percentage BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM 
    ReturnSalesComparison rsc
WHERE 
    rsc.total_returns > 0 
ORDER BY 
    return_rate_percentage DESC
LIMIT 100;
