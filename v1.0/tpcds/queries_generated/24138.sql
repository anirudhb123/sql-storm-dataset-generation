
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_month,
        cd.cd_gender,
        SUM(CASE WHEN sd.ss_customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS store_sales_count,
        SUM(CASE WHEN wd.ws_ship_customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS web_sales_count,
        COALESCE(MAX(sd.ss_net_paid_inc_tax), 0) AS max_store_sales,
        COALESCE(MAX(wd.ws_net_paid_inc_tax), 0) AS max_web_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_month ORDER BY SUM(sd.ss_net_paid_inc_tax) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        store_sales sd ON c.c_customer_sk = sd.ss_customer_sk
    LEFT JOIN 
        web_sales wd ON c.c_customer_sk = wd.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F' AND 
        (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_month IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_birth_month, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.c_birth_month,
        cs.cd_gender,
        cs.store_sales_count,
        cs.web_sales_count,
        cs.max_store_sales,
        cs.max_web_sales,
        CASE 
            WHEN cs.max_store_sales > cs.max_web_sales THEN 'Store'
            WHEN cs.max_store_sales < cs.max_web_sales THEN 'Web'
            ELSE 'Equal'
        END AS preferred_channel
    FROM 
        CustomerStats cs
    WHERE 
        cs.rn <= 10
)
SELECT 
    s.s_store_id,
    COALESCE(SUM(st.ss_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wd.ws_quantity), 0) AS total_web_quantity,
    COUNT(DISTINCT tc.c_customer_id) AS unique_customers
FROM 
    store s
LEFT JOIN 
    store_sales st ON s.s_store_sk = st.ss_store_sk
LEFT JOIN 
    web_sales wd ON st.ss_item_sk = wd.ws_item_sk
JOIN 
    TopCustomers tc ON tc.store_sales_count > 0 OR tc.web_sales_count > 0
GROUP BY 
    s.s_store_id
HAVING 
    ARRAY_LENGTH(ARRAY(SELECT DISTINCT tc.preferred_channel FROM TopCustomers tc WHERE tc.store_sales_count > 0), 1) > 1
ORDER BY 
    total_store_quantity DESC NULLS LAST;
