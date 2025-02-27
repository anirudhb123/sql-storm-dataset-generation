
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_id, ca.ca_city, w.w_warehouse_name
), demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.c_customer_id) AS customer_count,
        SUM(ss.total_sales) AS total_sales,
        SUM(ss.order_count) AS total_orders,
        AVG(ss.avg_net_profit) AS avg_net_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.total_sales,
    d.total_orders,
    d.avg_net_profit,
    RANK() OVER (ORDER BY d.total_sales DESC) AS sales_rank
FROM 
    demographics_summary d
ORDER BY 
    d.total_sales DESC
LIMIT 10;
