
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS online_purchase_count
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        c.c_customer_sk
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.purchase_count,
    cs.online_purchase_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    CASE 
        WHEN cs.total_spent BETWEEN 0 AND 100 THEN 'Low'
        WHEN cs.total_spent BETWEEN 101 AND 500 THEN 'Medium'
        WHEN cs.total_spent > 500 THEN 'High'
        ELSE 'Unknown'
    END AS spending_category
FROM 
    CustomerSales AS cs
JOIN 
    CustomerDemographics AS cd ON cs.c_customer_sk = cd.c_customer_sk
ORDER BY 
    cs.total_spent DESC
LIMIT 10;

SELECT 
    NULL AS d_date,
    NULL AS c_customer_sk,
    NULL AS total_spent
UNION ALL
SELECT 
    d.d_date,
    s.ss_customer_sk,
    SUM(s.ss_net_paid) AS total_spent
FROM 
    date_dim d
RIGHT JOIN 
    store_sales s ON d.d_date_sk = s.ss_sold_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_date, s.ss_customer_sk
HAVING 
    SUM(s.ss_net_paid) > 0
ORDER BY 
    total_spent DESC;
