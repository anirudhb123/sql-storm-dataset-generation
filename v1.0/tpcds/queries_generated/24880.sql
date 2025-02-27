
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),

sales_summary AS (
    SELECT 
        s.ss_store_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
        SUM(s.ss_net_paid) AS total_revenue,
        SUM(CASE WHEN s.ss_ext_discount_amt > 0 THEN s.ss_ext_discount_amt ELSE 0 END) AS total_discounts
    FROM 
        store_sales s
    GROUP BY 
        s.ss_store_sk
),

product_category AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        SUM(ws.ws_quantity) AS total_sold_quantity
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_category
),

ranked_sales AS (
    SELECT 
        ps.i_category,
        SUM(ps.total_sold_quantity) AS total_units_sold,
        DENSE_RANK() OVER (ORDER BY SUM(ps.total_sold_quantity) DESC) AS rank
    FROM 
        product_category ps 
    GROUP BY 
        ps.i_category
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ss.total_transactions,
    ss.total_revenue,
    ss.total_discounts,
    r.total_units_sold,
    CASE 
        WHEN r.rank <= 3 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    customer_hierarchy ch
LEFT JOIN 
    sales_summary ss ON ch.c_customer_sk = ss.ss_store_sk
LEFT JOIN 
    ranked_sales r ON r.rank <= 3
WHERE 
    (ch.level BETWEEN 0 AND 2)
    AND (ss.total_revenue IS NULL OR ss.total_revenue > 1000)
    AND (r.total_units_sold IS NOT NULL OR r.total_units_sold = 0)
ORDER BY 
    ss.total_revenue DESC NULLS LAST, 
    r.total_units_sold DESC;
