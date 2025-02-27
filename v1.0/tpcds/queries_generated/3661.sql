
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.order_number) AS order_count,
        SUM(COALESCE(ws.net_paid_inc_tax, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerData cd
)

SELECT 
    sd.web_site_id,
    sd.d_year,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.total_orders, 0) AS total_orders,
    COUNT(DISTINCT rc.c_customer_id) AS customer_count,
    AVG(rc.total_spent) AS average_spending,
    MAX(rc.rank) AS max_rank_gender
FROM 
    SalesData sd
LEFT JOIN 
    RankedCustomers rc ON sd.web_site_id = (SELECT ws.web_site_sk FROM web_site ws WHERE rc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = rc.c_customer_id) LIMIT 1)
LEFT JOIN 
    (SELECT 
         web_site_sk, d_year,
         SUM(net_paid_inc_tax) as total_sales,
         COUNT(order_number) as total_orders 
     FROM 
         web_sales 
     JOIN 
         date_dim ON sold_date_sk = d_date_sk 
     GROUP BY 
         web_site_sk, d_year) r 
ON sd.web_site_id = r.web_site_sk AND sd.d_year = r.d_year
GROUP BY 
    sd.web_site_id, sd.d_year
ORDER BY 
    sd.d_year DESC, total_sales DESC;
