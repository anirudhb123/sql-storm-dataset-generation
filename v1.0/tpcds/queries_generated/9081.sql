
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month AS sales_month,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2021
    GROUP BY 
        d.d_year, d.d_month, i.i_item_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
final_summary AS (
    SELECT 
        ss.sales_year,
        ss.sales_month,
        cs.c_customer_id,
        cs.cd_gender,
        ss.total_quantity,
        ss.total_profit,
        cs.orders_count,
        cs.total_spent
    FROM 
        sales_summary AS ss
    LEFT JOIN 
        customer_summary AS cs ON ss.total_profit > cs.total_spent
)
SELECT 
    fs.sales_year,
    fs.sales_month,
    fs.c_customer_id,
    fs.cd_gender,
    fs.total_quantity,
    fs.total_profit,
    fs.orders_count,
    fs.total_spent
FROM 
    final_summary AS fs
WHERE 
    fs.total_profit > 1000
ORDER BY 
    fs.sales_year, fs.sales_month, fs.total_profit DESC;
