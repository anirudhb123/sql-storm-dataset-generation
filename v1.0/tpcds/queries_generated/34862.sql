
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450599
    GROUP BY ss_store_sk, ss_item_sk
),
top_sales AS (
    SELECT 
        sd.ss_store_sk,
        sd.ss_item_sk,
        sd.total_sales
    FROM sales_data sd
    WHERE sd.sales_rank <= 5
),
locations AS (
    SELECT 
        s.s_store_sk,
        CONCAT(s.s_street_number, ' ', s.s_street_name, ' ', s.s_city, ', ', s.s_state, ' ', s.s_zip) AS full_address
    FROM store s
    WHERE s.s_state IN ('CA', 'NY', 'TX')
),
return_summary AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_store_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
)
SELECT 
    ls.full_address,
    ts.ss_item_sk,
    ts.total_sales,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM top_sales ts
LEFT JOIN locations ls ON ts.ss_store_sk = ls.s_store_sk
LEFT JOIN return_summary rs ON ts.ss_store_sk = rs.sr_store_sk
JOIN customer_demographics cd ON cd.cd_demo_sk IN (
    SELECT
        CASE 
            WHEN cd_marital_status = 'M' THEN cd_demo_sk
            ELSE NULL
        END
    FROM customer_demographics
)
WHERE cd.customer_count > 10
ORDER BY total_sales DESC, total_returns ASC;
