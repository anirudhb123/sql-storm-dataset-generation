
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        ss_ticket_number,
        ss_sales_price,
        ss_quantity,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_sales_price DESC) AS rnk
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (
            SELECT MAX(ss_sold_date_sk) 
            FROM store_sales
        )
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        SUM(ss_net_paid) AS total_spent
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ss_net_paid) > 500
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CombinedReport AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        s.ss_item_sk,
        s.ss_ticket_number,
        s.ss_sales_price,
        SUM(s.ss_quantity) AS total_quantity,
        MAX(s.ss_sales_price) AS max_price
    FROM 
        CustomerDetails c
    JOIN 
        HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
    JOIN 
        store_sales s ON hvc.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name, c.cd_gender, c.cd_marital_status, c.cd_education_status, s.ss_item_sk, s.ss_ticket_number
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status,
    s_item_details.ss_item_sk,
    s_item_details.total_quantity,
    s_item_details.max_price,
    COALESCE(rvs.sales_price, 0) AS ranked_sales_price
FROM 
    CombinedReport cr
LEFT JOIN 
    RankedSales rvs ON cr.ss_item_sk = rvs.ss_item_sk AND rvs.rnk <= 5
WHERE 
    cr.total_quantity > 10
ORDER BY 
    cr.cd_gender, cr.c_last_name, ranked_sales_price DESC;
