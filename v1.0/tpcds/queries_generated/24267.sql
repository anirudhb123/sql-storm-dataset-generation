
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_current_cdemo_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1975 AND 1995
    GROUP BY 
        c.c_customer_id, c.c_current_cdemo_sk
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > (
            SELECT AVG(ws_net_paid_inc_tax)
            FROM web_sales 
            WHERE ws_bill_customer_sk IS NOT NULL
        )
), 
customer_details AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        top_customers tc ON cd.cd_demo_sk = tc.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
), 
sales_per_category AS (
    SELECT 
        i.i_category,
        SUM(cs.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
), 
sales_by_region AS (
    SELECT 
        s.s_state,
        SUM(ss.ss_net_paid) AS state_sales,
        RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS state_rank
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_state
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    s.state_sales,
    COALESCE(s.state_sales, 0) AS adjusted_sales,
    CASE 
        WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
        ELSE cd.cd_credit_rating
    END AS credit_status,
    CONCAT('Total Profit from ', sc.i_category, ': ', sc.total_profit) AS category_profit_info
FROM 
    customer_details cd
FULL OUTER JOIN 
    sales_by_region s ON cd.cd_gender = COALESCE((SELECT 'M' FROM customer_demographics WHERE cd_gender = 'M'), (SELECT 'F' FROM customer_demographics WHERE cd_gender = 'F'))
LEFT JOIN 
    sales_per_category sc ON sc.rank = 1
ORDER BY 
    cd.customer_count DESC NULLS LAST, 
    s.state_sales DESC;
