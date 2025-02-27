
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY total_sales DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
)
SELECT 
    hvc.c_customer_sk,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    cs.total_sales,
    cs.order_count
FROM 
    high_value_customers hvc
JOIN 
    customer_sales cs ON hvc.c_customer_sk = cs.c_customer_sk
WHERE 
    hvc.rank <= 10
ORDER BY 
    hvc.cd_gender, cs.total_sales DESC;

WITH aggregated_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(ar.total_return_amt, 0) AS total_return_amt,
    COALESCE(ar.total_return_quantity, 0) AS total_return_quantity,
    cs.total_sales
FROM 
    customer c
LEFT JOIN 
    aggregated_returns ar ON c.c_customer_sk = ar.sr_customer_sk
LEFT JOIN 
    customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    (ar.total_return_amt IS NULL OR ar.total_return_amt < 500)
    AND (cs.total_sales IS NOT NULL)
    AND (cs.order_count IS NOT NULL)
ORDER BY 
    cs.total_sales DESC;
