
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month BETWEEN 1 AND 6
        AND c.c_birth_year IS NOT NULL
    GROUP BY ws.web_site_sk, ws_sold_date_sk
),
top_sites AS (
    SELECT 
        s.web_site_id,
        sr.total_quantity,
        sr.rank
    FROM sales_rank sr
    JOIN web_site s ON sr.web_site_sk = s.web_site_sk
    WHERE sr.rank <= 5
),
nullable_sales AS (
    SELECT 
        COALESCE(ws.cs_item_sk, 0) AS item_sk,
        COALESCE(SUM(ws.cs_sales_price), 0.00) AS total_sales
    FROM catalog_sales ws
    GROUP BY ws.cs_item_sk
),
returns_data AS (
    SELECT
        wr.returning_customer_sk,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IS NOT NULL
    GROUP BY wr.returning_customer_sk
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    n.total_sales,
    COALESCE(r.num_returns, 0) AS num_returns,
    COALESCE(r.total_return_amt, 0.00) AS total_return_amt,
    CASE 
        WHEN ts.total_quantity = 0 THEN 'No Purchases'
        ELSE CAST((r.total_return_amt / NULLIF(ts.total_quantity, 0)) * 100 AS DECIMAL(5,2)) || '%' 
    END AS return_rate,
    CASE 
        WHEN n.total_sales BETWEEN 100 AND 500 THEN 'Mid Range'
        WHEN n.total_sales > 500 THEN 'High Range'
        ELSE 'Low Range'
    END AS sales_category
FROM top_sites ts
LEFT JOIN nullable_sales n ON ts.web_site_id = n.item_sk
LEFT JOIN returns_data r ON ts.web_site_id = r.returning_customer_sk
ORDER BY ts.total_quantity DESC, n.total_sales ASC, r.num_returns DESC;
