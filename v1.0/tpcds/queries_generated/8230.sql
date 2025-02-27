
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COUNT(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
), 
store_stats AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(CASE WHEN sr.sr_item_sk IS NOT NULL THEN 1 END) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned
    FROM 
        store s
    LEFT JOIN 
        store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_purchases,
    cs.total_spent,
    is.i_item_id,
    is.i_item_desc,
    is.total_sold,
    is.total_revenue,
    ss.s_store_name,
    ss.total_returns,
    ss.total_returned
FROM 
    customer_stats cs
JOIN 
    item_stats is ON cs.total_purchases > 0
JOIN 
    store_stats ss ON ss.total_returns > 0
ORDER BY 
    cs.total_spent DESC, is.total_revenue DESC
LIMIT 100;
