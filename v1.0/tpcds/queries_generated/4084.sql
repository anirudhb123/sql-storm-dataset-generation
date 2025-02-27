
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
), 
SalesByAge AS (
    SELECT 
        c.c_customer_id,
        EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year AS age,
        cs.total_sales
    FROM 
        customer c
    INNER JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
), 
IncomeDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.total_sales) AS income_segment_sales
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        Income_Band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        CustomerSales cs ON cs.total_sales > ib.ib_lower_bound AND cs.total_sales <= ib.ib_upper_bound
    GROUP BY 
        cd.cd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
), 
RankedSales AS (
    SELECT 
        c.customer_id,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        cs.total_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_transactions > 5
)
SELECT 
    r.sales_rank,
    r.customer_id,
    r.total_sales,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(SUM(income_segment_sales), 0) AS total_income_segment_sales
FROM 
    RankedSales r
LEFT JOIN 
    IncomeDemographics ib ON r.customer_id = ib.cd_demo_sk
GROUP BY 
    r.sales_rank, r.customer_id, r.total_sales, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    r.sales_rank;
