
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        st.ws_sold_date_sk,
        st.ws_item_sk,
        s.total_profit + st.total_profit,
        s.total_orders + st.total_orders
    FROM 
        sales_trends s
    JOIN 
        web_sales st ON s.ws_item_sk = st.ws_item_sk AND st.ws_sold_date_sk = s.ws_sold_date_sk + 1
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(st.total_profit), 0) AS total_web_profit,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    d.avg_dep_count
FROM 
    customer_address ca
LEFT JOIN 
    sales_trends st ON ca.ca_address_sk = st.ws_item_sk
LEFT JOIN 
    customer_stats cs ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    demographics d ON d.cd_demo_sk = cs.c_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') AND
    (cs.total_spent > 1000 OR d.avg_dep_count IS NOT NULL)
GROUP BY 
    ca.ca_city, ca.ca_state, cs.order_count, cs.total_spent, d.avg_dep_count
HAVING 
    COUNT(st.ws_item_sk) > 0
ORDER BY 
    total_web_profit DESC, total_spent DESC;
