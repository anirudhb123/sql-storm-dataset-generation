
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cs.total_spent) AS avg_spending
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerSpending cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    dr.cd_gender,
    dr.cd_marital_status,
    dr.customer_count,
    dr.avg_spending,
    rs.total_sales AS top_sales 
FROM 
    Demographics dr
JOIN 
    RankedSales rs ON dr.customer_count = rs.sales_rank
WHERE 
    dr.avg_spending IS NOT NULL
ORDER BY 
    dr.avg_spending DESC, rs.top_sales DESC
LIMIT 10;
