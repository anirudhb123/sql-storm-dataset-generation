
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        SUM(sd.total_sales) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.web_site_id
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY customer_total_sales DESC) AS sales_rank
    FROM 
        CustomerStats
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.customer_total_sales
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.cd_gender, rc.cd_marital_status, rc.customer_total_sales DESC;
