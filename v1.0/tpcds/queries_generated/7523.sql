
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity
    FROM 
        ranked_sales rs
    WHERE 
        rs.rnk <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_age_group,
        SUM(ts.ws_sales_price * ts.ws_quantity) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        top_sales ts ON c.c_customer_sk = ts.ws_item_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_age_group
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_age_group,
    ci.total_sales,
    RANK() OVER (ORDER BY ci.total_sales DESC) AS sales_rank
FROM 
    customer_info ci
WHERE 
    ci.total_sales > 1000
ORDER BY 
    sales_rank;
