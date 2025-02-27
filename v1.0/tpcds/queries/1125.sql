
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.ss_ticket_number,
        SUM(s.ss_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        s.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
                                AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, s.ss_ticket_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ib.ib_income_band_sk, 0) AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesWithDemographics AS (
    SELECT 
        rs.c_customer_id,
        rs.ss_ticket_number,
        rs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_band
    FROM 
        RankedSales rs
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = rs.c_customer_id LIMIT 1)
)
SELECT 
    swd.cd_gender,
    swd.cd_marital_status,
    COUNT(swd.ss_ticket_number) AS total_orders,
    AVG(swd.total_sales) AS avg_order_value,
    SUM(swd.total_sales) AS total_sales,
    CASE 
        WHEN COUNT(swd.ss_ticket_number) > 0 THEN SUM(swd.total_sales) / COUNT(swd.ss_ticket_number) 
        ELSE 0 
    END AS average_sales_per_order
FROM 
    SalesWithDemographics swd
GROUP BY 
    swd.cd_gender, swd.cd_marital_status
HAVING 
    SUM(swd.total_sales) > 0
ORDER BY 
    total_sales DESC;
