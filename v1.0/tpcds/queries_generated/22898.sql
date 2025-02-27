
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status
    HAVING 
        total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM (
                SELECT 
                    SUM(ws.ws_net_paid) AS total_spent
                FROM 
                    web_sales ws
                GROUP BY 
                    ws.ws_bill_customer_sk
            ) AS avg_spending
        )
), 
ranked_sales AS (
    SELECT 
        s.web_site_sk,
        s.ws_sold_date_sk,
        s.total_quantity,
        s.total_sales,
        s.total_profit,
        RANK() OVER (PARTITION BY s.web_site_sk ORDER BY s.total_profit DESC) AS rank
    FROM 
        sales_summary s
)
SELECT 
    r.web_site_sk,
    r.total_quantity,
    r.total_sales,
    r.total_profit,
    COALESCE(hvc.c_first_name || ' ' || hvc.c_last_name, 'Unknown') AS top_customer,
    hvc.total_spent AS customer_spend,
    CASE 
        WHEN r.total_profit IS NULL THEN 'No profit' 
        ELSE 'Profit generated'
    END AS profit_status
FROM 
    ranked_sales r
LEFT JOIN 
    high_value_customers hvc ON r.web_site_sk = hvc.c_customer_sk
WHERE 
    r.rank = 1
ORDER BY 
    r.total_profit DESC, r.total_sales ASC
FETCH FIRST 10 ROWS ONLY;
