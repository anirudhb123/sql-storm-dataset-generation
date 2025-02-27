
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.order_number, 
        ws.sales_price, 
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
    )
),
SummarizedReturns AS (
    SELECT 
        cr.catalog_page_sk,
        SUM(CASE 
            WHEN cr.return_quantity IS NULL THEN 0 
            ELSE cr.return_quantity 
        END) AS total_returned_quantity,
        COALESCE(SUM(cr.return_amount), 0) AS total_returned_amount
    FROM catalog_returns cr
    GROUP BY cr.catalog_page_sk
),
IncomeBandSummary AS (
    SELECT 
        ib.income_band_sk,
        COUNT(hd.hd_demo_sk) AS demographic_count,
        MAX(hd.dep_count) AS max_dep_count,
        AVG(hd.dep_count) AS avg_dep_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.income_band_sk
),
CustomerWebBehavior AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.web_name,
        SUM(CASE WHEN wr.web_page_sk IS NOT NULL THEN wr.return_quantity ELSE 0 END) AS returned_items,
        AVG(ws.sales_price) AS average_spent
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.returning_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ship_customer_sk
    LEFT JOIN web_site w ON w.web_site_sk = ws.web_site_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, w.web_name
)
SELECT 
    R.web_site_sk,
    R.order_number,
    R.sales_price,
    R.net_profit,
    S.total_returned_quantity,
    S.total_returned_amount,
    I.demographic_count,
    I.max_dep_count,
    I.avg_dep_count,
    C.average_spent
FROM RankedSales R
LEFT JOIN SummarizedReturns S ON R.order_number = S.catalog_page_sk
FULL OUTER JOIN IncomeBandSummary I ON S.catalog_page_sk = I.income_band_sk
INNER JOIN CustomerWebBehavior C ON R.web_site_sk = C.c_customer_sk
WHERE (R.sales_rank <= 5 OR C.average_spent > 100) 
AND (S.total_returned_amount IS NULL OR S.total_returned_amount > 50)
ORDER BY R.net_profit DESC, C.average_spent ASC;
