
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
returns_data AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        wr.wr_web_page_sk
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_sales,
    sd.average_profit,
    rd.total_return_quantity,
    rd.total_return_amount
FROM 
    sales_data sd
LEFT JOIN 
    returns_data rd ON sd.web_site_id = rd.wr_web_page_sk
ORDER BY 
    sd.total_sales DESC;
