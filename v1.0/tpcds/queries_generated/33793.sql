
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        SUM(ss.net_paid) AS total_spent,
        COUNT(DISTINCT ss.ticket_number) AS purchase_count
    FROM 
        store_sales ss
    INNER JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        total_spent > 10000
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY total_spent DESC) AS income_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        high_value_customers hc ON c.c_customer_sk = hc.c_customer_sk
    WHERE 
        hc.purchase_count IS NOT NULL
),
total_returns AS (
    SELECT 
        COUNT(*) AS total_return_count,
        SUM(cr_returned_date_sk = cr_catalog_page_sk) AS return_count,
        SUM(cr_net_loss) AS total_loss
    FROM 
        catalog_returns
)
SELECT 
    d.d_date,
    SUM(COALESCE(hc.total_spent, 0)) AS total_sales_for_day,
    COUNT(DISTINCT cd.c_customer_id) AS active_customers,
    COALESCE(tr.total_return_count, 0) as total_return_count,
    COALESCE(tr.total_loss, 0) as total_loss
FROM 
    date_dim d
LEFT JOIN 
    high_value_customers hc ON d.d_date_sk = hc.total_spent
LEFT JOIN 
    customer_details cd ON cd.c_customer_id = hc.total_spent
LEFT JOIN 
    total_returns tr ON 1=1
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date;
