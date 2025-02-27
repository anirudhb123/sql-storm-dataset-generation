
WITH RECURSIVE cte_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        s.s_store_sk,
        SUM(sss.ss_net_profit) + c.total_profit,
        c.level + 1
    FROM 
        cte_sales c
    JOIN 
        store_sales s ON c.ss_store_sk = s.ss_store_sk
    JOIN 
        store_sales sss ON s.ss_item_sk = sss.ss_item_sk
    WHERE 
        c.level < 5
    GROUP BY 
        s.s_store_sk
),
item_analytics AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        AVG(ws.ws_net_profit) AS avg_profit,
        MIN(ws.ws_ext_discount_amt) AS min_discount,
        NULLIF(MAX(ws.ws_ext_sales_price), 0) AS max_sales_price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_credit_rating
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
return_summary AS (
    SELECT 
        cr.cr_reason_sk,
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amt) AS total_return_amt
    FROM 
        catalog_returns cr
    JOIN 
        reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY 
        cr.cr_reason_sk, r.r_reason_desc
)
SELECT 
    s.s_store_id,
    sa.total_profit,
    ia.avg_profit,
    ia.min_discount,
    ia.max_sales_price,
    hvc.c_customer_id,
    hvc.order_count,
    hvc.total_spent,
    rs.return_count,
    rs.total_return_amt
FROM 
    store s
JOIN 
    cte_sales sa ON s.s_store_sk = sa.ss_store_sk
JOIN 
    item_analytics ia ON ia.i_item_id = (
        SELECT i.i_item_id FROM item i ORDER BY RANDOM() LIMIT 1
    )
LEFT JOIN 
    high_value_customers hvc ON hvc.total_spent > 5000
LEFT JOIN 
    return_summary rs ON rs.return_count >= 10
WHERE 
    s.s_number_employees > (
        SELECT AVG(s_number_employees) FROM store
    )
ORDER BY 
    sa.total_profit DESC, hvc.total_spent DESC
LIMIT 50;
