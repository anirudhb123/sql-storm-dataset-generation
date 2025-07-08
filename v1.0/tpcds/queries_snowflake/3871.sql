
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),

TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_net_paid,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_paid DESC) AS customer_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_purchases > 5
),

CustomerDemographicsWithSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        tc.total_net_paid
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cda.ca_city,
    cda.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales_from_web,
    ROUND(AVG(SUM(ws.ws_sales_price)) OVER (PARTITION BY c.c_customer_sk), 2) AS avg_sales_per_order,
    LISTAGG(DISTINCT CONCAT(p.p_promo_name, ': ', p.p_cost), ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS applied_promotions
FROM 
    customer c
LEFT JOIN 
    customer_address cda ON c.c_current_addr_sk = cda.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    CustomerDemographicsWithSales cd ON c.c_customer_sk = cd.c_customer_sk
WHERE 
    cd.total_net_paid > 100
    AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL)
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, cda.ca_city, cda.ca_state, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_from_web DESC
LIMIT 10;
