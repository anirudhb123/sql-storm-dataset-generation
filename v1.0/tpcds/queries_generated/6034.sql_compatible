
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk, d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON ss.web_site_sk = c.c_current_addr_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_quantity,
        cs.total_profit,
        RANK() OVER (PARTITION BY cs.cd_marital_status ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        customer_summary cs
)
SELECT 
    rc.c_customer_sk,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_quantity,
    rc.total_profit,
    rc.profit_rank
FROM 
    ranked_customers rc
WHERE 
    rc.profit_rank <= 10
ORDER BY 
    rc.cd_marital_status, rc.total_profit DESC;
