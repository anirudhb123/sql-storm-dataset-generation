
WITH sales_data AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        d_year,
        d_month_seq,
        c_gender,
        c_preferred_cust_flag
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws_order_number, d_year, d_month_seq, c_gender, c_preferred_cust_flag
), sales_summary AS (
    SELECT 
        d_year,
        d_month_seq,
        c_gender,
        c_preferred_cust_flag,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        SUM(total_discount) AS total_discount
    FROM 
        sales_data
    GROUP BY 
        d_year, d_month_seq, c_gender, c_preferred_cust_flag
)
SELECT 
    d_year,
    d_month_seq,
    c_gender,
    c_preferred_cust_flag,
    order_count,
    total_quantity,
    total_sales,
    total_discount,
    ROUND(total_sales / NULLIF(order_count, 0), 2) AS avg_sales_per_order,
    ROUND(total_discount / NULLIF(order_count, 0), 2) AS avg_discount_per_order
FROM 
    sales_summary
ORDER BY 
    d_year, d_month_seq, c_gender, c_preferred_cust_flag;
