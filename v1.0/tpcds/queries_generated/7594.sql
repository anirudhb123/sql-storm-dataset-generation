
WITH EnhancedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year,
        d.d_month_seq,
        st.s_store_id,
        c.c_gender,
        c.c_birth_country
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        store st ON ws.ws_ship_addr_sk = st.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, st.s_store_id, c.c_gender, c.c_birth_country
),
SalesAnalysis AS (
    SELECT 
        es.total_quantity,
        es.total_sales,
        es.total_discount,
        es.total_tax,
        es.order_count,
        RANK() OVER (PARTITION BY es.d_year, es.d_month_seq ORDER BY es.total_sales DESC) as sales_rank,
        es.c_gender,
        es.c_birth_country
    FROM 
        EnhancedSales es
)
SELECT 
    sa.c_gender,
    sa.c_birth_country,
    AVG(sa.total_sales) AS avg_sales,
    SUM(sa.total_discount) AS total_discount,
    COUNT(DISTINCT sa.order_count) AS unique_orders
FROM 
    SalesAnalysis sa
WHERE 
    sales_rank <= 10
GROUP BY 
    sa.c_gender, sa.c_birth_country
ORDER BY 
    avg_sales DESC;
