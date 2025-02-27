
WITH RecursiveSales AS (
    SELECT 
        ss_item_sk,
        ss_sold_date_sk,
        ss_quantity,
        ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) as sale_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN '2023-01-01' AND '2023-12-31'
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        SUM(ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ss_net_paid) > 1000
),
PromotionsUsed AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_promo_sk) AS promo_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 50
    GROUP BY 
        ws_bill_customer_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(r.r_reason_desc, 'No Reason') AS reason_description
    FROM 
        item i
    LEFT JOIN 
        reason r ON i.i_item_sk = r.r_reason_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    COALESCE(pu.total_spent, 0) AS total_spent,
    COALESCE(ph.promo_count, 0) AS promo_count,
    i.i_item_desc,
    SUM(CASE WHEN rs.sale_rank = 1 THEN rs.ss_quantity ELSE 0 END) AS last_year_quantity,
    AVG(i.i_current_price) FILTER (WHERE i.i_current_price >= 20 AND i.i_current_price <= 100) AS avg_discounted_price
FROM 
    customer c
LEFT JOIN 
    HighValueCustomers pu ON c.c_customer_sk = pu.c_customer_sk
LEFT JOIN 
    PromotionsUsed ph ON c.c_customer_sk = ph.ws_bill_customer_sk
LEFT JOIN 
    ItemDetails i ON c.c_current_hdemo_sk = i.i_item_sk
LEFT JOIN 
    RecursiveSales rs ON i.i_item_sk = rs.ss_item_sk
WHERE 
    c.c_birth_year IS NOT NULL
    AND (c.c_birth_year < 1980 OR c.c_birth_year IS NULL)
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_sk, i.i_item_sk, pu.total_spent, ph.promo_count
HAVING 
    SUM(rs.ss_quantity) > 0
ORDER BY 
    total_spent DESC;
