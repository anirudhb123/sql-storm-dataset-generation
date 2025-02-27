
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MIN(d.d_date_sk)
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
high_value_customers AS (
    SELECT * 
    FROM customer_sales 
    WHERE order_count > 1 AND total_spent > (
        SELECT AVG(total_spent) FROM customer_sales
    )
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
demographic_summary AS (
    SELECT 
        cvc.c_customer_id,
        cvc.total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(dc.hd_income_band_sk) AS income_band_count
    FROM 
        high_value_customers cvc 
    JOIN 
        customer_demographics cd ON cvc.c_customer_id = cd.cd_demo_sk
    LEFT JOIN 
        demographic_summary dm ON dm.c_customer_id = cvc.c_customer_id
    GROUP BY 
        cvc.c_customer_id, cvc.total_spent, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
final_report AS (
    SELECT 
        d.c_customer_id,
        d.total_spent,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        CASE 
            WHEN d.income_band_count > 0 THEN 'Present'
            ELSE 'Absent'
        END AS income_band_status,
        COUNT(wh.w_warehouse_id) AS num_of_warehouses
    FROM 
        demographic_summary d
    LEFT JOIN 
        warehouse wh ON (CASE 
            WHEN d.total_spent > 1000 THEN 1 
            ELSE 0 
        END) = (CASE 
            WHEN d.cd_marital_status = 'M' THEN 1 ELSE 0 
        END)
    GROUP BY 
        d.c_customer_id, d.total_spent, d.cd_gender, d.cd_marital_status, d.cd_education_status, d.income_band_count
)
SELECT 
    f.c_customer_id,
    f.total_spent,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.income_band_status,
    CASE 
        WHEN f.num_of_warehouses > 0 THEN 'Available'
        ELSE 'Not Available'
    END AS warehouse_availability
FROM 
    final_report f
WHERE 
    f.income_band_status = 'Present'
    AND (f.total_spent IS NOT NULL OR f.cd_gender IS NOT NULL)
ORDER BY 
    f.total_spent DESC, f.cd_gender, f.cd_marital_status;
