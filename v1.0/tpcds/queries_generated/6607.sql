
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
), CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM
        customer_demographics cd
), IncomeBands AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        income_band ib
), SalesSummary AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        CustomerSales cs
    JOIN
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN
        IncomeBands ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_orders,
    s.cd_gender,
    s.cd_marital_status,
    CASE 
        WHEN s.total_sales < 1000 THEN 'Low'
        WHEN s.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY s.cd_gender ORDER BY s.total_sales DESC) AS sales_rank
FROM
    SalesSummary s
WHERE 
    s.total_orders > 1
ORDER BY
    s.cd_gender,
    s.total_sales DESC;
