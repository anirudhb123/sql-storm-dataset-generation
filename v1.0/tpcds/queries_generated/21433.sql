
WITH ranked_sales AS (
    SELECT 
        wss.ws_sales_price,
        wss.ws_quantity,
        wss.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY wss.ws_item_sk ORDER BY wss.ws_sold_date_sk DESC) AS rnk
    FROM web_sales wss
    WHERE wss.ws_ship_date_sk IS NOT NULL 
        AND wss.ws_sales_price > 0
        AND EXISTS (
            SELECT 1
            FROM store_sales sss
            WHERE sss.ss_item_sk = wss.ws_item_sk
            AND sss.ss_ticket_number > 1000
        )
),
last_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_revenue
    FROM ranked_sales rs
    WHERE rs.rnk = 1
    GROUP BY rs.ws_item_sk
    HAVING SUM(rs.ws_sales_price * rs.ws_quantity) > (
        SELECT AVG(ws.ws_sales_price) 
        FROM web_sales ws
        WHERE ws.ws_item_sk IS NOT NULL
    )
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        NULLIF(c.c_email_address, '') AS email,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
sales_summary AS (
    SELECT
        ci.c_customer_id,
        ci.cd_gender,
        ci.marital_status,
        li.total_revenue,
        CASE
            WHEN li.total_revenue IS NULL THEN 'No Sales'
            WHEN li.total_revenue < 1000 THEN 'Low Revenue'
            ELSE 'High Revenue'
        END AS revenue_category
    FROM customer_info ci
    LEFT JOIN last_sales li ON ci.c_customer_id = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT ws_item_sk FROM last_sales))
)
SELECT
    ss.revenue_category,
    COUNT(ss.c_customer_id) AS customer_count,
    AVG(ss.total_revenue) AS average_revenue
FROM sales_summary ss
WHERE ss.revenue_category IS NOT NULL
GROUP BY ss.revenue_category
ORDER BY customer_count DESC
LIMIT 5;

