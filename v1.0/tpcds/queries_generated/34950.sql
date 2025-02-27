
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
date_sales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_net_profit) AS monthly_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
order_sales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(ws.ws_net_paid) AS max_paid,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    sh.c_customer_id,
    sh.cd_gender,
    sh.cd_marital_status,
    ds.d_year,
    ds.d_month_seq,
    ds.monthly_profit,
    os.total_quantity,
    os.max_paid,
    os.avg_price
FROM 
    sales_hierarchy sh
FULL OUTER JOIN 
    date_sales ds ON sh.c_customer_sk = ds.d_year -- assuming some logic for commonality
LEFT JOIN 
    order_sales os ON os.ws_order_number = sh.c_customer_id -- hypothetical connection
WHERE 
    (sh.total_sales > 1000 OR ds.monthly_profit > 5000)
    AND (sh.cd_gender IS NOT NULL OR sh.cd_marital_status IS NOT NULL)
ORDER BY 
    ds.d_year, ds.d_month_seq, sh.total_sales DESC
LIMIT 100;
