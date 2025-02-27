
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_selling_items AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        sales.total_quantity, 
        sales.total_sales, 
        sales.total_profit,
        RANK() OVER (PARTITION BY sales.ws_sold_date_sk ORDER BY sales.total_quantity DESC) as sales_rank
    FROM 
        sales_summary sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
),
customer_segment AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(s.total_sales) AS total_sales_by_gender_marital
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary s ON s.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    tsi.i_item_id, 
    tsi.i_item_desc,
    csg.cd_gender,
    csg.cd_marital_status,
    csg.customer_count,
    csg.total_sales_by_gender_marital,
    ts.total_quantity,
    ts.total_sales,
    ts.total_profit
FROM 
    top_selling_items ts  
JOIN 
    customer_segment csg ON csg.total_sales_by_gender_marital > 0
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.total_sales DESC, csg.customer_count DESC;
