
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status 
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000
),
SalesByState AS (
    SELECT 
        ca.ca_state, 
        SUM(hv.total_sales) AS total_high_value_sales,
        COUNT(hv.c_customer_sk) AS high_value_customer_count
    FROM 
        HighValueCustomers hv
    JOIN 
        customer_address ca ON hv.c_customer_sk = ca.ca_address_id
    GROUP BY 
        ca.ca_state
)
SELECT 
    sbs.ca_state,
    sbs.total_high_value_sales,
    sbs.high_value_customer_count,
    ROUND(sbs.total_high_value_sales / NULLIF(sbs.high_value_customer_count, 0), 2) AS avg_sales_per_high_value_customer
FROM 
    SalesByState sbs
ORDER BY 
    sbs.total_high_value_sales DESC
LIMIT 10;
