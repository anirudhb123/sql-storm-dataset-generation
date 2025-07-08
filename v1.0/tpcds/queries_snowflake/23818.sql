
WITH RevenueCTE AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        cw.c_customer_id,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cw.c_customer_id ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer cw ON ws.ws_bill_customer_sk = cw.c_customer_sk
    JOIN 
        customer_demographics cd ON cw.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL AND 
        (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
),
TopRevenues AS (
    SELECT 
        c_customer_id,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        RevenueCTE
    WHERE 
        rank_sales <= 5
    GROUP BY 
        c_customer_id
),
FilteredRevenues AS (
    SELECT 
        tr.c_customer_id,
        tr.total_revenue,
        CASE 
            WHEN tr.total_revenue > 1000 THEN 'High Value'
            WHEN tr.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS revenue_category
    FROM 
        TopRevenues tr
    WHERE 
        tr.total_revenue IS NOT NULL
)
SELECT 
    fr.c_customer_id,
    fr.total_revenue,
    fr.revenue_category,
    da.d_month_seq,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    MAX(ws.ws_net_profit) AS max_profit
FROM 
    FilteredRevenues fr
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = fr.c_customer_id LIMIT 1)
LEFT JOIN 
    date_dim da ON da.d_date_sk = ws.ws_sold_date_sk
GROUP BY 
    fr.c_customer_id, fr.total_revenue, fr.revenue_category, da.d_month_seq
HAVING 
    COUNT(ws.ws_order_number) > 0
ORDER BY 
    fr.total_revenue DESC, revenue_category ASC
LIMIT 100;
