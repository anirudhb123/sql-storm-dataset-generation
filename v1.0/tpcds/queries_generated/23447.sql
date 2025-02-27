
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_paid DESC) AS rank,
        DENSE_RANK() OVER (ORDER BY ws.net_paid DESC, ws.web_site_sk) AS dense_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y' AND ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_week_seq BETWEEN 1 AND 52
    )
),
RankedSales AS (
    SELECT 
        sd.web_site_sk,
        sd.web_name,
        sd.net_paid,
        sd.rank,
        sd.dense_rank,
        CASE
            WHEN sd.rank = 1 THEN 'Top Performer'
            WHEN sd.dense_rank <= 5 THEN 'Top 5'
            ELSE 'Regular Performer'
        END AS performance_category
    FROM SalesData sd
    WHERE sd.web_site_sk IS NOT NULL
),
AggregateSales AS (
    SELECT 
        web_site_sk,
        COUNT(*) AS total_sales,
        SUM(net_paid) AS total_net_paid
    FROM RankedSales
    GROUP BY web_site_sk
)
SELECT 
    r.web_site_sk,
    r.web_name,
    r.performance_category,
    a.total_sales,
    a.total_net_paid,
    CASE 
        WHEN a.total_sales > 100 THEN 'High Volume'
        WHEN a.total_sales BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM RankedSales r
JOIN AggregateSales a ON r.web_site_sk = a.web_site_sk
LEFT JOIN customer_demographics cd ON r.web_site_sk = (SELECT TOP 1 c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = r.web_site_sk)
WHERE r.rank <= 10 OR a.total_net_paid > (SELECT AVG(total_net_paid) FROM AggregateSales)
ORDER BY r.web_name, a.total_net_paid DESC
OPTION (MAXDOP 4);
