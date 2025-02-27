
WITH RECURSIVE sales_trends AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        st.d_year - 1,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        sales_trends st
    JOIN 
        date_dim d ON st.d_year = d.d_year + 1
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        st.d_year
),
customer_states AS (
    SELECT 
        c.c_customer_id,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_state
),
top_states AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_customers,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        customer_states
    WHERE 
        rank_sales <= 3
    GROUP BY 
        ca_state
)
SELECT 
    st.d_year,
    ts.ca_state,
    ts.total_customers,
    ts.total_sales,
    trends.total_sales AS previous_year_sales,
    COALESCE(ROUND((ts.total_sales - trends.total_sales) / NULLIF(trends.total_sales, 0) * 100, 2), 0) AS sales_growth_percentage
FROM 
    sales_trends trends
JOIN 
    top_states ts ON ts.total_sales > 10000
ORDER BY 
    st.d_year DESC, ts.total_sales DESC;
