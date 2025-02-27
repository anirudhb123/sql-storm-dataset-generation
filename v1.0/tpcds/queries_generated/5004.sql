
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
        cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count,
        cd.cd_dep_employed_count, cd.cd_dep_college_count
),
HighValueCustomers AS (
    SELECT 
        *
    FROM 
        CustomerData
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM CustomerData)
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN total_spent ELSE 0 END) AS male_spent,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN total_spent ELSE 0 END) AS female_spent,
        COUNT(*) AS customer_count
    FROM 
        HighValueCustomers hv
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ss.ss_sold_date_sk) FROM store_sales ss WHERE ss.ss_customer_sk = hv.c_customer_sk)
    GROUP BY 
        d.d_year
)
SELECT 
    s.d_year,
    s.male_spent,
    s.female_spent,
    s.customer_count,
    (s.male_spent + s.female_spent) AS total_spent
FROM 
    SalesSummary s
ORDER BY 
    s.d_year DESC;
