
WITH RECURSIVE revenue_summary AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_date_sk,
        SUM(ws.net_profit) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.bill_customer_sk, ws.ship_date_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(SUM(ws.net_profit), 0) AS total_net_profit
    FROM 
        customer cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cs.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.net_profit) > (
            SELECT 
                AVG(total_sales) FROM revenue_summary
        )
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT tc.c_customer_sk) AS customer_count,
    AVG(tc.total_net_profit) AS avg_net_profit
FROM 
    top_customers tc
JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    AVG(tc.total_net_profit) > (SELECT AVG(td.total_sales) FROM revenue_summary td)
ORDER BY 
    customer_count DESC;
