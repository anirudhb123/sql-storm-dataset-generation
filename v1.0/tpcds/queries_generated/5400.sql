
WITH SalesAggregates AS (
    SELECT 
        d.d_year, 
        d.d_month_seq,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_ext_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_ext_sales_price ELSE 0 END) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd 
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    a.d_year, 
    a.d_month_seq, 
    a.total_web_sales, 
    a.total_catalog_sales, 
    a.total_store_sales, 
    a.web_sales_count, 
    a.catalog_sales_count, 
    a.store_sales_count, 
    cd.cd_gender, 
    cd.cd_marital_status,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
FROM 
    SalesAggregates a
JOIN 
    CustomerDemographics cd ON cd.ib_lower_bound <= a.total_web_sales AND cd.ib_upper_bound > a.total_web_sales
JOIN 
    TopCustomers tc ON tc.total_spent > a.total_catalog_sales
ORDER BY 
    a.d_year DESC, a.d_month_seq DESC;
