
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
),
average_data AS (
    SELECT 
        c.c_customer_id,
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_order_count,
        AVG(unique_items_purchased) AS avg_unique_items
    FROM 
        customer_data c
    GROUP BY 
        c.c_customer_id
),
income_brackets AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(a.avg_sales) AS total_avg_sales
    FROM 
        household_demographics h
    JOIN 
        average_data a ON h.hd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = a.c_customer_id)
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(AVG(income_brackets.total_avg_sales), 0) AS avg_sales_per_income_bracket
FROM 
    income_band ib
LEFT JOIN 
    income_brackets ON ib.ib_income_band_sk = income_brackets.hd_income_band_sk
GROUP BY 
    ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    ib.ib_lower_bound;
