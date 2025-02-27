
WITH aggregated_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2022
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_sk
),
ranked_sales AS (
    SELECT
        asales.web_site_sk,
        asales.total_quantity,
        asales.total_sales,
        asales.total_profit,
        RANK() OVER (ORDER BY asales.total_profit DESC) AS profit_rank
    FROM 
        aggregated_sales asales
)
SELECT 
    r.web_site_sk,
    r.total_quantity,
    r.total_sales,
    r.total_profit,
    r.profit_rank,
    w.w_warehouse_name,
    w.w_city,
    w.w_state
FROM 
    ranked_sales r
JOIN 
    web_site w ON r.web_site_sk = w.web_site_sk
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_profit DESC;
