
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.net_paid) AS total_sales,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_paid) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND ws.sold_date_sk IN (
          SELECT d_date_sk
          FROM date_dim
          WHERE d_year = 2023
            AND d_month_seq BETWEEN 1 AND 3
            AND d_holiday = 'N'
      )
    GROUP BY ws.web_site_id, ws.web_name
),
return_data AS (
    SELECT 
        wr.web_page_sk,
        SUM(wr.return_amt) AS total_returns,
        COUNT(wr.return_number) AS total_return_orders
    FROM web_returns wr
    GROUP BY wr.web_page_sk
)

SELECT 
    s.web_site_id,
    s.web_name,
    s.total_sales,
    s.total_orders,
    s.avg_order_value,
    r.total_returns,
    r.total_return_orders,
    CASE 
        WHEN r.total_returns IS NULL THEN 'No Returns'
        WHEN r.total_returns > s.total_sales * 0.1 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_comment
FROM sales_data s
LEFT JOIN return_data r ON s.web_site_id = r.web_page_sk
WHERE s.sales_rank <= 5
ORDER BY s.total_sales DESC;
