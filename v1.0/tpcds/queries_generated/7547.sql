
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        c.c_birth_month,
        c.c_birth_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_gender, c.c_birth_month, c.c_birth_year
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        ds.c_gender,
        SUM(ds.total_sales) AS monthly_sales
    FROM 
        date_dim d
    JOIN 
        CustomerSales ds ON d.d_date_sk = EXTRACT(YEAR FROM CURRENT_DATE) * 100 + d.d_month_seq
    GROUP BY 
        d.d_year, d.d_month_seq, ds.c_gender
),
RankedSales AS (
    SELECT 
        ms.d_month_seq,
        ms.c_gender,
        ms.monthly_sales,
        RANK() OVER (PARTITION BY ms.d_month_seq ORDER BY ms.monthly_sales DESC) AS sales_rank
    FROM 
        MonthlySales ms
)
SELECT 
    d_year,
    c_gender,
    ROUND(SUM(monthly_sales), 2) AS total_sales,
    COUNT(DISTINCT c_customer_sk) AS unique_customers
FROM 
    RankedSales rs
WHERE 
    sales_rank <= 5
GROUP BY 
    d_year, c_gender
ORDER BY 
    d_year, c_gender;
