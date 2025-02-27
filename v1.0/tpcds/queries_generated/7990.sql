
WITH RevenueByCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(r.total_revenue) AS total_revenue
    FROM 
        RevenueByCustomer r
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    dd.d_date,
    COALESCE(ds.web_sales, 0) AS web_sales,
    COALESCE(ds.store_sales, 0) AS store_sales,
    COALESCE(ds.catalog_sales, 0) AS catalog_sales,
    ds.web_orders,
    ds.store_orders,
    ds.catalog_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_revenue
FROM 
    DailySales ds
JOIN 
    CustomerDemographics cd ON ds.total_revenue = cd.total_revenue
JOIN 
    date_dim dd ON dd.d_date = ds.d_date
ORDER BY 
    dd.d_date DESC, total_revenue DESC;
