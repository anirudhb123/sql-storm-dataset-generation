
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
    
    UNION ALL
    
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_sales + COALESCE((SELECT SUM(z.ws_net_paid) 
                                    FROM web_sales z 
                                    WHERE z.ws_bill_customer_sk = cs.c_customer_sk), 0) AS total_sales,
        cs.order_count + COALESCE((SELECT COUNT(z.ws_order_number) 
                                    FROM web_sales z 
                                    WHERE z.ws_bill_customer_sk = cs.c_customer_sk), 0) AS order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > 1000
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_sales,
        ai.ca_city,
        ai.ca_state,
        ai.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer_sales cs
    JOIN 
        address_info ai ON cs.c_customer_sk = ai.ca_address_sk
    JOIN 
        demographics d ON cs.c_customer_sk = d.cd_demo_sk
    WHERE 
        cs.total_sales IS NOT NULL
    ORDER BY 
        cs.total_sales DESC
)
SELECT 
    customer_id,
    total_sales,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    RANK() OVER (PARTITION BY ca_state, ca_country ORDER BY total_sales DESC) AS sales_rank
FROM 
    sales_summary
WHERE 
    (cd_purchase_estimate > 1000 OR cd_gender IS NULL)
    AND total_sales > (SELECT AVG(total_sales) FROM customer_sales);
