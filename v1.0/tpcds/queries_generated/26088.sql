
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cd.cd_purchase_estimate) OVER() AS median_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
RankedInfo AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        si.total_sales,
        si.order_count,
        RANK() OVER (PARTITION BY ci.ca_state ORDER BY si.total_sales DESC) AS sales_rank
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    total_sales,
    order_count,
    sales_rank,
    CASE 
        WHEN sales_rank <= 10 THEN 'Top 10'
        WHEN sales_rank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS category
FROM 
    RankedInfo
WHERE 
    total_sales > (SELECT AVG(total_sales) FROM SalesInfo)
ORDER BY 
    ca_state, total_sales DESC;
