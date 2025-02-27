
WITH sales_summary AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        EXTRACT(YEAR FROM d.d_date) AS sale_year,
        d.d_month_seq AS sale_month
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_id,
        EXTRACT(YEAR FROM d.d_date),
        d.d_month_seq
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status
),
profit_rankings AS (
    SELECT
        web_site_id,
        sale_year,
        sale_month,
        total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sale_year, sale_month ORDER BY total_net_profit DESC) AS rank
    FROM
        sales_summary
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.web_site_id,
    ss.sale_year,
    ss.sale_month,
    ss.total_net_profit,
    ss.order_count,
    ss.avg_quantity_per_order,
    pr.rank
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON cs.total_spent = ss.total_net_profit
JOIN 
    profit_rankings pr ON ss.web_site_id = pr.web_site_id AND ss.sale_year = pr.sale_year AND ss.sale_month = pr.sale_month
WHERE 
    pr.rank <= 10
ORDER BY 
    ss.sale_year, ss.sale_month, pr.rank;
