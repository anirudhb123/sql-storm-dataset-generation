
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
sales_per_hour AS (
    SELECT 
        d.d_date,
        t.t_hour,
        SUM(ws.ws_sales_price) AS daily_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date, t.t_hour
),
ranked_sales AS (
    SELECT 
        web_site_sk,
        web_name,
        total_sales,
        ntile(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        sales_data
),
customer_returned_sales AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
combined_data AS (
    SELECT 
        r.web_site_sk,
        r.web_name,
        r.total_sales,
        p.d_date,
        p.t_hour,
        COALESCE(c.return_count, 0) AS return_count,
        COALESCE(c.total_return_amt, 0) AS total_return_amt,
        r.sales_quartile
    FROM 
        ranked_sales r
    JOIN 
        sales_per_hour p ON r.web_site_sk = p.t_hour
    LEFT JOIN 
        customer_returned_sales c ON r.web_site_sk = c.c_customer_sk
)
SELECT 
    DISTINCT web_site_sk, 
    web_name, 
    total_sales, 
    d_date, 
    t_hour, 
    return_count, 
    total_return_amt,
    CASE 
        WHEN sales_quartile = 1 THEN 'Low Tier'
        WHEN sales_quartile = 2 THEN 'Medium Tier'
        WHEN sales_quartile = 3 THEN 'High Tier'
        ELSE 'Top Tier'
    END AS sales_tier
FROM 
    combined_data 
WHERE 
    return_count > 5 
    OR total_return_amt > (
        SELECT AVG(total_return_amt) FROM customer_returned_sales
    ) 
ORDER BY 
    total_sales DESC NULLS LAST
LIMIT 50;
