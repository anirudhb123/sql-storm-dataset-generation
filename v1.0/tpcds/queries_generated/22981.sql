
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ws.ws_sold_date_sk,
        COALESCE(DATEADD(DAY, 1, d.d_date), '9999-12-31') AS next_sold_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 
      AND ws.ws_sales_price IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales_count,
        SUM(rs.ws_sales_price) AS total_sales_value,
        MAX(rs.price_rank) AS max_price_rank
    FROM RankedSales rs
    GROUP BY rs.ws_item_sk
),
CustomerFeedback AS (
    SELECT 
        c.c_customer_sk,
        AVG(COALESCE(f.feedback_score, 0)) AS avg_feedback
    FROM customer c
    LEFT JOIN (
        SELECT 
            wr_returning_customer_sk AS customer_id,
            AVG(wr_return_amt_inc_tax / NULLIF(wr_return_quantity, 0)) AS feedback_score
        FROM web_returns
        WHERE wr_return_quantity > 0
        GROUP BY wr_returning_customer_sk
    ) f ON c.c_customer_sk = f.customer_id
    GROUP BY c.c_customer_sk
)
SELECT 
    a.ws_item_sk,
    a.total_sales_count,
    a.total_sales_value,
    c.avg_feedback,
    CASE 
        WHEN c.avg_feedback IS NULL THEN 'No Feedback'
        WHEN c.avg_feedback > 4 THEN 'Highly Rated'
        WHEN c.avg_feedback BETWEEN 3 AND 4 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS feedback_category,
    r.next_sold_date
FROM AggregatedSales a
JOIN CustomerFeedback c ON a.ws_item_sk = c.c_customer_sk
LEFT JOIN RankedSales r ON a.ws_item_sk = r.ws_item_sk AND r.price_rank = 1
WHERE a.total_sales_value > (
        SELECT AVG(total_sales_value) 
        FROM AggregatedSales 
        WHERE total_sales_count > 5
      )
ORDER BY a.total_sales_value DESC
FETCH FIRST 50 ROWS ONLY;
