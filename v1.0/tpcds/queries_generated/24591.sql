
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FilteredCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state
    FROM 
        CustomerInfo ci
    WHERE 
        ci.customer_rank <= 100 AND 
        ci.cd_purchase_estimate > 5000 AND 
        (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
),
SalesDetails AS (
    SELECT 
        rc.ws_bill_customer_sk,
        rc.total_sales,
        rc.order_count,
        cf.c_first_name,
        cf.c_last_name,
        CASE 
            WHEN rc.order_count > 5 THEN 'Frequent'
            ELSE 'Infrequent'
        END AS customer_type
    FROM 
        RankedSales rc
    JOIN 
        FilteredCustomers cf ON rc.ws_bill_customer_sk = cf.c_customer_sk
)
SELECT 
    sd.c_first_name,
    sd.c_last_name,
    sd.total_sales,
    sd.order_count,
    sd.customer_type,
    CASE 
        WHEN sd.total_sales IS NULL THEN 'No Sales Record'
        ELSE CONCAT('Total Sales: $', FORMAT(sd.total_sales, 2))
    END AS sales_summary,
    COALESCE(
        (SELECT AVG(sd2.total_sales) 
         FROM SalesDetails sd2 
         WHERE sd2.customer_type = sd.customer_type 
         AND sd2.total_sales IS NOT NULL
        ), 0) AS average_sales_for_type
FROM 
    SalesDetails sd
ORDER BY 
    sd.total_sales DESC, 
    sd.c_first_name ASC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
