
WITH RECURSIVE monthly_sales AS (
    SELECT 
        d.d_year AS year,
        d.d_month AS month,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month
    UNION ALL
    SELECT 
        ms.year,
        ms.month + 1,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        monthly_sales ms
    JOIN 
        date_dim d ON (ms.year = d.d_year AND ms.month + 1 = d.d_month)
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        ms.year, ms.month
),
ranked_sales AS (
    SELECT 
        year,
        month,
        total_sales,
        RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        monthly_sales
),
top_sales AS (
    SELECT 
        year,
        month,
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 3
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Not Specified') AS gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    ci.gender,
    ts.year,
    ts.month,
    SUM(ts.total_sales) AS sales_per_gender,
    AVG(ci.total_profit) AS avg_profit
FROM 
    top_sales ts
JOIN 
    customer_info ci ON EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = ci.c_customer_sk 
        AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = ts.year AND d.d_month = ts.month)
    )
GROUP BY 
    ci.gender, ts.year, ts.month
ORDER BY 
    ts.year, ts.month, sales_per_gender DESC;
