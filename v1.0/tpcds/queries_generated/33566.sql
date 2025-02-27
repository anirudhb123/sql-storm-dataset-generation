
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        i.i_item_desc
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.rank <= 5
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        COUNT(wr.wr_order_number) AS total_returns
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, d.d_year
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    c.c_customer_sk,
    SUM(cd.total_returns) AS annual_returns,
    CASE 
        WHEN SUM(cd.total_returns) IS NULL THEN 'No Returns'
        WHEN SUM(cd.total_returns) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM top_sales t
LEFT JOIN customer_data cd ON t.ws_item_sk = cd.c_customer_sk
LEFT JOIN customer c ON cd.c_customer_sk = c.c_customer_sk
GROUP BY t.ws_item_sk, t.total_quantity, t.total_sales, c.c_customer_sk
ORDER BY t.total_sales DESC
LIMIT 50;
