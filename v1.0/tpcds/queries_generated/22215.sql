
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
),
total_sales AS (
    SELECT 
        bill_customer_sk,
        SUM(ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(ts.total_spent, 0) AS total_spent,
    COALESCE(ts.unique_items, 0) AS unique_items,
    CASE
        WHEN ts.total_spent IS NULL THEN 'No Purchases'
        WHEN ts.total_spent > 1000 THEN 'High Roller'
        WHEN ts.total_spent BETWEEN 500 AND 1000 THEN 'Mid-tier'
        ELSE 'Budget Shopper'
    END AS shopper_type
FROM 
    customer_details cd
LEFT JOIN 
    total_sales ts ON cd.c_customer_id = ts.bill_customer_sk
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = cd.c_customer_sk AND ss.ss_quantity > 0
    )
ORDER BY 
    shopper_type DESC, total_spent DESC;
