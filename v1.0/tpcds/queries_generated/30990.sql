
WITH RECURSIVE sales_data AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_net_paid) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk
),
item_category AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk AND CURRENT_DATE BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ic.i_category,
    ic.i_brand,
    ic.promotion_name,
    SUM(sd.total_sales) AS total_category_sales,
    COUNT(DISTINCT ci.c_customer_id) AS unique_customers,
    AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(sd.total_transactions) AS max_transactions
FROM 
    sales_data sd
JOIN 
    item_category ic ON sd.ss_item_sk = ic.i_item_sk
LEFT JOIN 
    customer_info ci ON ci.purchase_rank <= 10
WHERE 
    sd.sales_rank <= 5
GROUP BY 
    ic.i_category, ic.i_brand, ic.promotion_name
HAVING 
    SUM(sd.total_sales) > 1000
ORDER BY 
    total_category_sales DESC
LIMIT 50;
