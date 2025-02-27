
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_quantity,
        total_sales,
        total_discount
    FROM 
        SalesSummary
    WHERE 
        rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COALESCE(c.c_birth_month, 1) AS birth_month,
        COALESCE(c.c_birth_year, 2000) AS birth_year
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound,
    SUM(ts.total_sales) AS customer_total_sales,
    SUM(ts.total_discount) AS customer_total_discount,
    STRING_AGG(DISTINCT CONCAT(CAST(cd.birth_month AS VARCHAR), '|', CAST(cd.birth_year AS VARCHAR)), ', ') AS birth_info
FROM 
    CustomerDetails cd
JOIN 
    TopCustomers ts ON cd.c_customer_id = ts.customer_id
GROUP BY 
    cd.c_customer_id, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.ib_lower_bound, cd.ib_upper_bound
ORDER BY 
    customer_total_sales DESC;
