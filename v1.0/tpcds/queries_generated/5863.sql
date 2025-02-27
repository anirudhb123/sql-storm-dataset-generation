
WITH SalesSummary AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_store_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        s.s_store_id, s.s_store_name, d.d_year
),
DemographicsSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_sales,
        SUM(ss.order_count) AS order_count,
        SUM(ss.unique_customers) AS unique_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.total_sales,
    ds.order_count,
    ds.unique_customers,
    RANK() OVER (PARTITION BY ds.cd_gender ORDER BY ds.total_sales DESC) AS sales_rank
FROM 
    DemographicsSummary ds
ORDER BY 
    ds.cd_gender, sales_rank;
