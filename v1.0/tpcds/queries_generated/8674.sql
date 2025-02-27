
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY 
        ws.web_site_sk
),
top_sales_sites AS (
    SELECT 
        web_site_sk,
        total_net_profit,
        order_count
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 5
)
SELECT 
    w.web_site_id,
    t.total_net_profit,
    t.order_count,
    w.web_name,
    w.web_manager
FROM 
    top_sales_sites t
JOIN 
    web_site w ON t.web_site_sk = w.web_site_sk
ORDER BY 
    t.total_net_profit DESC;
