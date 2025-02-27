
WITH RECURSIVE sales_rank AS (
    SELECT 
        ss_customer_sk,
        ss_item_sk,
        ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY ss_net_paid DESC) AS rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk, 
        i.i_current_price, 
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
        AND (i.i_item_desc LIKE '%special%' OR i.i_item_desc IS NULL)
    GROUP BY 
        i.i_item_sk, 
        i.i_current_price
),
top_customers AS (
    SELECT 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.ca_city, 
        sr.ss_net_paid,
        ir.total_quantity_sold,
        RANK() OVER (ORDER BY sr.ss_net_paid DESC) AS customer_rank
    FROM 
        sales_rank sr
    JOIN 
        customer_info ci ON sr.ss_customer_sk = ci.c_customer_sk
    JOIN 
        item_summary ir ON sr.ss_item_sk = ir.i_item_sk
    WHERE 
        ir.total_quantity_sold > 10
),
final_report AS (
    SELECT 
        fc.c_first_name, 
        fc.c_last_name, 
        fc.ca_city,
        COALESCE(fc.ss_net_paid, 0) AS total_spent_last_day,
        COALESCE(SUM(rr.total_quantity_sold), 0) AS total_quantity_ranked,
        COUNT(rr.customer_rank) AS ranking_count
    FROM 
        top_customers fc
    LEFT JOIN 
        (
            SELECT 
                sr.ss_customer_sk,
                ir.total_quantity_sold
            FROM 
                sales_rank sr
            JOIN 
                item_summary ir ON sr.ss_item_sk = ir.i_item_sk
            WHERE 
                sr.rank <= 5
        ) rr ON fc.ss_customer_sk = rr.ss_customer_sk
    GROUP BY 
        fc.c_first_name, 
        fc.c_last_name, 
        fc.ca_city
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    f.total_spent_last_day,
    f.total_quantity_ranked,
    CASE 
        WHEN f.ranking_count IS NULL THEN 'No Rankings'
        WHEN f.ranking_count = 0 THEN 'Ranked Not Sold'
        ELSE 'Total Ranked'
    END AS rank_status
FROM 
    final_report f
WHERE 
    f.total_spent_last_day > 100 
    OR f.total_quantity_ranked > 20
ORDER BY 
    f.total_spent_last_day DESC, 
    f.total_quantity_ranked ASC;
