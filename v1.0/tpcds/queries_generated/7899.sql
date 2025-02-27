
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(wp.wp_creation_date_sk) AS max_creation_date,
        MIN(wp.wp_access_date_sk) AS min_access_date,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
return_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    s.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.order_count,
    sd.max_creation_date,
    sd.min_access_date,
    sd.avg_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    rd.total_return_quantity,
    rd.total_return_amount
FROM 
    sales_data sd
JOIN 
    return_data rd ON sd.ws_item_sk = rd.wr_item_sk
JOIN 
    customer_data cd ON cd.c_customer_sk = (SELECT c_customer_sk FROM web_sales WHERE ws_item_sk = sd.ws_item_sk LIMIT 1)
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
