
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        customer_id, 
        total_sales,
        order_count 
    FROM 
        RankedSales
    WHERE 
        rank_sales = 1 AND
        total_sales > (SELECT AVG(total_sales) FROM RankedSales)
),
FrequentReturners AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) as return_count
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
    GROUP BY 
        wr_returning_customer_sk
    HAVING 
        return_count > (SELECT AVG(return_count) FROM (
            SELECT COUNT(wr_order_number) AS return_count 
            FROM web_returns 
            GROUP BY wr_returning_customer_sk
        ) AS averages)
)
SELECT 
    hs.customer_id,
    hs.total_sales,
    hs.order_count,
    COALESCE(fr.return_count, 0) AS return_count,
    hs.total_sales - COALESCE(fr.return_count * 10.00, 0) AS effective_sales
FROM 
    HighSpenders hs
LEFT JOIN 
    FrequentReturners fr ON hs.customer_id = fr.wr_returning_customer_sk
WHERE 
    effective_sales > 0
ORDER BY 
    effective_sales DESC
LIMIT 100
UNION ALL
SELECT 
    'TOTALS' AS customer_id,
    SUM(total_sales) AS total_sales,
    SUM(order_count) AS total_orders,
    SUM(COALESCE(return_count, 0)) AS total_return_count,
    SUM(total_sales) - SUM(COALESCE(return_count * 10.00, 0)) AS total_effective_sales
FROM 
    HighSpenders hs
LEFT JOIN 
    FrequentReturners fr ON hs.customer_id = fr.wr_returning_customer_sk
HAVING 
    total_effective_sales > 0
ORDER BY 
    total_effective_sales DESC;
