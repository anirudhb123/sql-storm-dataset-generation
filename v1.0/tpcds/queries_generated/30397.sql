
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.sold_date_sk BETWEEN 2400 AND 2700
    GROUP BY ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        ss.bill_customer_sk,
        ss.total_sales,
        ss.order_count
    FROM sales_summary ss
    WHERE ss.sales_rank <= 10
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_summary AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(tc.total_sales, 0) AS total_sales,
        tc.order_count
    FROM customer_details cd
    LEFT JOIN top_customers tc ON cd.c_customer_sk = tc.bill_customer_sk
),
return_summary AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_amt) AS total_returns,
        COUNT(wr.return_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.order_count,
    COALESCE(rs.total_returns, 0) AS total_returns,
    CASE
        WHEN cs.total_sales = 0 THEN NULL
        ELSE (COALESCE(rs.total_returns, 0)::float / cs.total_sales::float) * 100
    END AS return_rate_percentage
FROM customer_summary cs
LEFT JOIN return_summary rs ON cs.c_customer_sk = rs.returning_customer_sk
ORDER BY cs.total_sales DESC, cs.order_count DESC;
