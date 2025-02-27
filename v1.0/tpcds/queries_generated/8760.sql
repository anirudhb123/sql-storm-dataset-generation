
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
returns_data AS (
    SELECT 
        wr.wr_web_site_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        wr.wr_web_site_sk
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_net_profit,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    (sd.total_sales - COALESCE(rd.total_return_amount, 0)) AS net_revenue
FROM 
    sales_data sd
LEFT JOIN 
    returns_data rd ON sd.web_site_id = rd.wr_web_site_sk
ORDER BY 
    net_revenue DESC
LIMIT 10;
