
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank,
        DATE(d.d_date) AS sale_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.web_site_sk, DATE(d.d_date)
),
ReturnCount AS (
    SELECT 
        wr.refunded_customer_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.refunded_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COALESCE(rt.total_return_amount, 0) AS total_return_amt
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN ReturnCount rt ON c.c_customer_sk = rt.refunded_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.income_band,
    COUNT(DISTINCT rs.sale_date) AS active_sale_days,
    SUM(rs.total_sales) AS total_sales,
    SUM(cs.total_return_amt) AS total_returns,
    CASE 
        WHEN SUM(rs.total_sales) > 0 THEN (SUM(cs.total_returns) / SUM(rs.total_sales))
        ELSE NULL 
    END AS return_ratio,
    NTILE(4) OVER (ORDER BY SUM(rs.total_sales)) AS sales_quartile
FROM CustomerDetails cs
JOIN RankedSales rs ON cs.c_customer_id = rs.web_site_sk
GROUP BY cs.c_customer_id, cs.cd_gender, cs.cd_marital_status, cs.income_band
HAVING 
    (SUM(rs.total_sales) IS NOT NULL AND SUM(rs.total_sales) > 1000) 
    OR (cs.cd_marital_status = 'M' AND COUNT(DISTINCT rs.sale_date) > 10)
ORDER BY return_ratio ASC NULLS LAST;
