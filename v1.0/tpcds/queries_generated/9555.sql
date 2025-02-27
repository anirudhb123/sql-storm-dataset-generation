
WITH sales_summary AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT web_sales.ws_order_number) AS total_orders,
        COUNT(web_sales.ws_item_sk) AS total_items_sold
    FROM 
        customer
    JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        date_dim.d_year = 2023
    GROUP BY 
        customer.c_customer_id, customer.c_first_name, customer.c_last_name
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_analysis AS (
    SELECT 
        ss.c_customer_id,
        ss.c_first_name,
        ss.c_last_name,
        ss.total_sales,
        ss.total_orders,
        ss.total_items_sold,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        sales_summary ss
    LEFT JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    sa.total_sales,
    sa.total_orders,
    sa.total_items_sold,
    sa.cd_gender,
    sa.cd_marital_status,
    CONCAT('$', FORMAT(sa.ib_lower_bound, 0), ' - $', FORMAT(sa.ib_upper_bound, 0)) AS income_band,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank
FROM 
    sales_analysis sa
JOIN 
    customer c ON sa.c_customer_id = c.c_customer_id
WHERE 
    sa.total_sales > 1000
ORDER BY 
    sales_rank
LIMIT 10;
