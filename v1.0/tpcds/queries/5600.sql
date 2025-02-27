
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_profit,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    d.d_date AS sale_date,
    i.i_item_id,
    i.i_item_desc,
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    rs.total_quantity,
    rs.total_sales,
    rs.total_discount,
    rs.total_profit
FROM 
    ranked_sales rs
INNER JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
INNER JOIN 
    date_dim d ON rs.ws_sold_date_sk = d.d_date_sk
INNER JOIN 
    customer_data cs ON rs.ws_item_sk IN (SELECT wr_item_sk FROM web_returns WHERE wr_returning_customer_sk = cs.c_customer_sk)
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    sale_date, total_profit DESC;
