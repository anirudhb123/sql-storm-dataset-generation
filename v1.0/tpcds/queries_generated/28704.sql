
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
HighValueCustomers AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales
    FROM 
        TopCustomers tc
    WHERE 
        tc.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
),
FinalAnalysis AS (
    SELECT 
        hvc.c_customer_id,
        hvc.c_first_name,
        hvc.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hvc.total_sales
    FROM 
        HighValueCustomers hvc
    JOIN 
        CustomerDemographics cd ON hvc.c_customer_id = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name,
    hvc.total_sales,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.ib_lower_bound,
    hvc.ib_upper_bound
FROM 
    FinalAnalysis hvc
ORDER BY 
    hvc.total_sales DESC;
