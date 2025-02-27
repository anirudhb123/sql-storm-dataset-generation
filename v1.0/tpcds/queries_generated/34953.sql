
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
high_rollers AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        demo.cd_gender,
        demo.cd_income_band,
        SUM(sales_cte.total_sales) AS total_spent
    FROM customer
    JOIN customer_demographics demo ON customer.c_current_cdemo_sk = demo.cd_demo_sk
    JOIN sales_cte ON sales_cte.ws_item_sk IN (
        SELECT it.i_item_sk 
        FROM item it 
        WHERE it.i_current_price > 100
    )
    WHERE demo.cd_income_band IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000)
    GROUP BY customer.c_customer_sk, customer.c_first_name, customer.c_last_name, demo.cd_gender, demo.cd_income_band
),
top_customers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM high_rollers
),
daily_sales AS (
    SELECT
        d.d_date,
        SUM(ws_ext_sales_price) AS daily_sales,
        COUNT(DISTINCT ws_ticket_number) AS transaction_count
    FROM web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
final_report AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent,
        tc.spending_rank,
        ds.daily_sales,
        ds.transaction_count,
        CASE 
            WHEN ds.daily_sales > 10000 THEN 'High Sales'
            ELSE 'Normal Sales'
        END as sales_category
    FROM top_customers tc
    RIGHT JOIN daily_sales ds ON ds.daily_sales > 5000
)
SELECT 
    first_name,
    last_name,
    total_spent,
    spending_rank,
    COALESCE(daily_sales, 0) AS daily_sales,
    transaction_count,
    sales_category
FROM final_report
WHERE spending_rank <= 100
ORDER BY total_spent DESC, sales_category;
