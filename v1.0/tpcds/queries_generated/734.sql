
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        w.w_warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
            AND d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)
        )
    GROUP BY 
        s.s_store_id, w.w_warehouse_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
return_summary AS (
    SELECT 
        sr_store_sk, 
        COUNT(*) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    ss.s_store_id,
    s.w_warehouse_id,
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Purchases'
        WHEN cs.total_spent >= 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    sales_summary ss
INNER JOIN 
    customer_summary cs ON ss.sales_rank = 1
LEFT JOIN 
    return_summary rs ON ss.s_store_id = rs.sr_store_sk
WHERE 
    (ss.total_sales > 10000 OR rs.total_returns IS NOT NULL)
ORDER BY 
    ss.total_sales DESC, cs.total_spent ASC;
