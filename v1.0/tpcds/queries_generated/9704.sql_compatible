
WITH SalesData AS (
    SELECT 
        sd.ss_sold_date_sk,
        SUM(sd.ss_quantity) AS total_quantity,
        SUM(sd.ss_ext_sales_price) AS total_sales,
        SUM(sd.ss_ext_discount_amt) AS total_discount,
        c.c_gender,
        c.c_marital_status,
        c.c_birth_month,
        w.w_warehouse_id,
        d.d_year
    FROM store_sales sd
    JOIN customer c ON sd.ss_customer_sk = c.c_customer_sk
    JOIN warehouse w ON sd.ss_store_sk = w.w_warehouse_sk
    JOIN date_dim d ON sd.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        sd.ss_sold_date_sk, 
        c.c_gender, 
        c.c_marital_status, 
        c.c_birth_month, 
        w.w_warehouse_id, 
        d.d_year
), AggregatedSales AS (
    SELECT
        sd.c_gender,
        sd.c_marital_status,
        sd.c_birth_month,
        sd.w_warehouse_id,
        sd.d_year,
        COUNT(DISTINCT sd.ss_sold_date_sk) AS num_days_active,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_sales) AS total_sales_amount,
        SUM(sd.total_discount) AS total_discount_amount
    FROM SalesData sd
    GROUP BY 
        sd.c_gender, 
        sd.c_marital_status, 
        sd.c_birth_month, 
        sd.w_warehouse_id, 
        sd.d_year
)
SELECT 
    ag.c_gender,
    ag.c_marital_status,
    ag.c_birth_month,
    ag.w_warehouse_id,
    ag.d_year,
    ag.num_days_active,
    ag.total_quantity_sold,
    ag.total_sales_amount,
    ag.total_discount_amount,
    CASE 
        WHEN ag.total_sales_amount > 1000000 THEN 'High'
        WHEN ag.total_sales_amount BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_classification
FROM AggregatedSales ag
ORDER BY ag.total_sales_amount DESC
LIMIT 100;
