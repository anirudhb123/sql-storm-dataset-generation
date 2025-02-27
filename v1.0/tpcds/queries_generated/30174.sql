
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk AS store_id,
        s.s_store_name,
        COALESCE(s.cc_call_center_sk, -1) AS cc_id,
        SUM(st.ss_net_paid) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales st ON s.s_store_sk = st.ss_store_sk
    LEFT JOIN 
        call_center c ON s.s_company_id = c.cc_company
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.cc_call_center_sk
    
    UNION ALL
    
    SELECT 
        sh.store_id,
        sh.s_store_name,
        COALESCE(sh.cc_id, -1) AS cc_id,
        SUM(st.ss_net_paid) AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales st ON sh.store_id = st.ss_store_sk
    WHERE 
        sh.total_sales > 1000
    GROUP BY 
        sh.store_id, sh.s_store_name, sh.cc_id
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_summary cs
)
SELECT 
    s.s_store_name,
    sh.total_sales AS store_total_sales,
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_spent,
    COALESCE(ic.ib_income_band_sk, -1) AS income_band,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Spending'
        WHEN tc.total_spent > 1000 THEN 'High Spender'
        ELSE 'Regular Spender' 
    END AS customer_category
FROM 
    sales_hierarchy sh
JOIN 
    top_customers tc ON sh.store_id = tc.c_customer_sk
LEFT JOIN 
    household_demographics hd ON tc.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ic ON hd.hd_income_band_sk = ic.ib_income_band_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    store_total_sales DESC, total_spent DESC;
