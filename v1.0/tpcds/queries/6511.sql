
WITH sales_summary AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
final_summary AS (
    SELECT 
        ds.c_customer_id,
        ds.total_sales,
        ds.total_orders,
        ds.avg_sales_price,
        ds.total_tax,
        ds.total_profit,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.customer_count
    FROM 
        sales_summary ds
    JOIN 
        demographics_summary dm ON ds.c_customer_id = (
            SELECT c.c_customer_id 
            FROM customer c 
            WHERE c.c_customer_sk IN (
                SELECT c.c_customer_sk 
                FROM customer c 
                WHERE c.c_current_cdemo_sk = dm.cd_demo_sk
                LIMIT 1))
)
SELECT 
    fs.c_customer_id,
    fs.total_sales,
    fs.total_orders,
    fs.avg_sales_price,
    fs.total_tax,
    fs.total_profit,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.customer_count
FROM 
    final_summary fs
ORDER BY 
    fs.total_sales DESC
LIMIT 50;
