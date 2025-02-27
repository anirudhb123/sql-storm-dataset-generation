
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_item_sk
),
quantity_and_amount AS (
    SELECT 
        si.i_item_sk,
        si.i_item_id,
        COALESCE(SUM(sh.total_sales_quantity), 0) AS total_sold,
        COALESCE(SUM(sh.total_net_paid), 0) AS total_amount,
        CASE 
            WHEN SUM(sh.total_net_paid) > 10000 THEN 'High'
            WHEN SUM(sh.total_net_paid) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        item si
    LEFT JOIN 
        sales_hierarchy sh ON si.i_item_sk = sh.ss_item_sk
    GROUP BY 
        si.i_item_sk, si.i_item_id
),
top_items AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_amount DESC) AS rank
    FROM 
        quantity_and_amount
)
SELECT 
    ti.i_item_id,
    ti.total_sold,
    ti.total_amount,
    ti.sales_category,
    COALESCE(CAST(ROUND(tw.avg_quantity, 2) AS DECIMAL(10,2)), 0) AS avg_sold_quantity,
    COALESCE(CAST(ROUND(tw.avg_amount, 2) AS DECIMAL(10,2)), 0) AS avg_sold_amount
FROM 
    top_items ti
LEFT JOIN (
    SELECT 
        COUNT(sh.ss_ticket_number) AS avg_quantity,
        AVG(sh.total_net_paid) AS avg_amount,
        sh.ss_item_sk
    FROM 
        store_sales sh
    WHERE 
        sh.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sh.ss_item_sk
) tw ON ti.i_item_sk = tw.ss_item_sk
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_amount DESC;
