
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RankedCustomers rc
    JOIN 
        customer c ON rc.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rc.rank <= 10
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
SalesByGender AS (
    SELECT 
        tc.cd_gender,
        SUM(ms.total_sales) AS gender_sales
    FROM 
        TopCustomers tc
    JOIN 
        web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        MonthlySales ms ON CONCAT(ms.d_year, '-', ms.d_month_seq) = CONCAT(year(ws.ws_sold_date_sk), '-', month(ws.ws_sold_date_sk))
    GROUP BY 
        tc.cd_gender
)
SELECT 
    sbg.cd_gender,
    sbg.gender_sales,
    (SELECT COUNT(DISTINCT c.c_customer_sk) FROM customer c JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk WHERE cd.cd_gender = sbg.cd_gender) AS customer_count
FROM 
    SalesByGender sbg
ORDER BY 
    sbg.gender_sales DESC;
