
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_dow IN (1, 2, 3)
        )
    GROUP BY 
        c.c_customer_id, ws.ws_order_number
),
ReturnStats AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
AggregateResults AS (
    SELECT 
        r.c_customer_id,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(rt.total_returns, 0) AS total_returns,
        COALESCE(rt.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(s.total_sales, 0) = 0 THEN NULL
            ELSE ROUND((COALESCE(rt.total_return_amount, 0) * 100.0) / NULLIF(s.total_sales, 0), 2)
        END AS return_percentage
    FROM 
        (SELECT DISTINCT c_customer_id FROM RankedSales) r
    LEFT JOIN 
        (SELECT c_customer_id, SUM(total_sales) AS total_sales FROM RankedSales GROUP BY c_customer_id) s ON r.c_customer_id = s.c_customer_id
    LEFT JOIN 
        ReturnStats rt ON rt.wr_returning_customer_sk = r.c_customer_id
)
SELECT 
    a.c_customer_id,
    a.total_sales,
    a.total_returns,
    a.total_return_amount,
    a.return_percentage,
    CASE 
        WHEN a.return_percentage IS NULL AND a.total_sales > 500 THEN 'High Volume No Returns'
        WHEN a.return_percentage > 5 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS customer_category
FROM 
    AggregateResults a
WHERE 
    a.return_percentage IS NOT NULL OR a.total_sales < 100
ORDER BY 
    a.total_sales DESC NULLS LAST;
