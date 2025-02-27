
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws_ext_sales_price) > 1000
),
store_summary AS (
    SELECT 
        s.s_store_id,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        AVG(ss_sales_price) AS avg_sale_value
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    st.s_store_id,
    st.total_sales,
    st.total_revenue,
    st.avg_sale_value,
    COALESCE(hvc.total_spent, 0) AS high_value_customer_spending,
    (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_state = 'CA') AS california_addresses,
    (SELECT COUNT(*) 
     FROM ship_mode sm 
     WHERE sm.sm_type LIKE '%Ground%') AS ground_shipment_modes
FROM 
    store_summary st
LEFT JOIN 
    high_value_customers hvc ON hvc.c_customer_sk IN (
        SELECT TOP 5 c_customer_sk 
        FROM high_value_customers 
        ORDER BY total_spent DESC
    )
WHERE 
    st.total_revenue > (SELECT AVG(ss_net_paid) FROM store_sales)
ORDER BY 
    st.total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
