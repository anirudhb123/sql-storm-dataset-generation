
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, hd.hd_income_band_sk
),
TopSales AS (
    SELECT 
        c_customer_id,
        cd_gender,
        hd_income_band_sk,
        total_sales
    FROM 
        CustomerSales
    WHERE 
        sales_rank <= 5
),
AverageSales AS (
    SELECT 
        hd_income_band_sk,
        AVG(total_sales) AS avg_sales
    FROM 
        TopSales
    GROUP BY 
        hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(as.avg_sales, 0) AS average_sales
FROM 
    income_band ib
LEFT JOIN 
    AverageSales as ON ib.ib_income_band_sk = as.hd_income_band_sk
WHERE 
    (ib.ib_lower_bound IS NOT NULL OR ib.ib_upper_bound IS NOT NULL)
ORDER BY 
    ib.ib_income_band_sk;

WITH RECURSIVE DateRange AS (
    SELECT MIN(d_date) AS start_date, MAX(d_date) AS end_date
    FROM date_dim
    UNION ALL
    SELECT DATE_ADD(start_date, INTERVAL 1 DAY)
    FROM DateRange
    WHERE start_date < (SELECT MAX(d_date) FROM date_dim)
)
SELECT 
    d.d_date,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_revenue
FROM 
    DateRange dr
JOIN 
    date_dim d ON dr.start_date = d.d_date
LEFT JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date DESC
LIMIT 30;
