
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk, 
        SUM(sr.return_quantity) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr.returned_date_sk ORDER BY SUM(sr.return_quantity) DESC) AS rank
    FROM store_returns sr
    LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY sr.returned_date_sk
),
MaxReturned AS (
    SELECT 
        r.returned_date_sk, 
        r.total_returned_quantity
    FROM RankedReturns r
    WHERE r.rank = 1
),
SalesData AS (
    SELECT 
        d.d_date, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(SUM(ws.ws_coupon_amt), 0) AS total_coupons
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
)
SELECT 
    s.s_state,
    sd.total_sales,
    md.total_returned_quantity,
    COALESCE(md.total_returned_quantity, 0) - COALESCE(sd.total_sales, 0) AS net_effect,
    CASE 
        WHEN COALESCE(md.total_returned_quantity, 0) > COALESCE(sd.total_sales, 0) THEN 'Returns exceed sales'
        ELSE 'Sales exceed returns'
    END AS return_sales_comparison
FROM SalesData sd
FULL OUTER JOIN MaxReturned md ON sd.total_sales > 1000
JOIN store s ON s.s_store_sk = (SELECT ss.s_store_sk FROM store_sales ss WHERE ss.ss_sold_date_sk = sd.d_date)
WHERE s.s_state IS NOT NULL
ORDER BY net_effect DESC;
