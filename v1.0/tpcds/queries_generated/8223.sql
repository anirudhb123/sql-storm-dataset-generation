
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk AS demo_id,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        cd_income_band_sk
    FROM 
        customer_demographics
),
IncomeBands AS (
    SELECT 
        ib_income_band_sk AS income_band_id,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        income_band
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.total_sales,
        ss.total_orders,
        ss.unique_items
    FROM 
        customer c
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.demo_id
    JOIN 
        IncomeBands ib ON d.cd_income_band_sk = ib.income_band_id
    JOIN 
        SalesSummary ss ON ss.customer_id = c.c_customer_sk
    WHERE 
        ss.total_sales > 1000
        AND d.cd_marital_status = 'M'
        AND ib.ib_lower_bound <= 75000
        AND ib.ib_upper_bound > 50000
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    fc.cd_dep_count,
    fc.ib_lower_bound,
    fc.ib_upper_bound,
    fc.total_sales,
    fc.total_orders,
    fc.unique_items
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.total_sales DESC;
