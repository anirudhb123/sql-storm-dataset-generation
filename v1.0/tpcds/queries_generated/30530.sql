
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
FilteredSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.year,
        cs.rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL
        AND cs.rank <= 10
),
HighIncomeCustomers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_income_band_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
        AND hd.hd_buy_potential LIKE 'High%'
)
SELECT 
    DISTINCT fs.c_first_name,
    fs.c_last_name,
    fs.total_sales,
    CASE 
        WHEN fs.rank IS NULL THEN 'No Sales'
        ELSE 'Top Seller'
    END AS performance_label,
    ic.cd_gender,
    ic.cd_marital_status
FROM 
    FilteredSales fs
LEFT JOIN 
    HighIncomeCustomers ic ON fs.c_customer_sk = ic.cd_demo_sk
WHERE 
    ic.cd_demo_sk IS NOT NULL
ORDER BY 
    fs.total_sales DESC,
    fs.c_last_name;
