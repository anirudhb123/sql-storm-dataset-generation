
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (6, 7) 
    GROUP BY 
        ws.web_site_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_dep_count, 0) AS dependent_count,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
avg_sales AS (
    SELECT 
        cs_bill_cdemo_sk,
        AVG(cs_net_paid) AS avg_purchase
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_cdemo_sk
)
SELECT 
    cu.c_customer_sk,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_purchase_estimate,
    cu.dependent_count,
    cu.vehicle_count,
    s.total_sales,
    COALESCE(a.avg_purchase, 0) AS avg_purchase,
    CASE 
        WHEN s.total_sales > (SELECT AVG(total_sales) FROM ranked_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    customer_data cu
JOIN 
    ranked_sales s ON cu.c_customer_sk = s.web_site_sk
LEFT JOIN 
    avg_sales a ON cu.c_customer_sk = a.cs_bill_cdemo_sk
WHERE 
    cu.cd_gender = 'M' 
    AND cu.cd_marital_status = 'S' 
    AND s.sales_rank <= 10
ORDER BY 
    s.total_sales DESC, 
    cu.c_customer_sk;
