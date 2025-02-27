
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_item_sk, 
        ss_net_paid, 
        ss_sales_price, 
        ss_discount_amt AS discount_amount,
        1 AS level
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales) 
        AND ss_net_paid IS NOT NULL
    
    UNION ALL
    
    SELECT 
        s.ss_item_sk, 
        s.ss_net_paid, 
        s.ss_sales_price, 
        s.ss_ext_discount_amt,
        cte.level + 1
    FROM 
        store_sales s 
    INNER JOIN 
        Sales_CTE cte ON s.ss_item_sk = cte.ss_item_sk 
    WHERE 
        s.ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
        AND cte.level < 5
),
Item_Summary AS (
    SELECT 
        i.i_item_id,
        COUNT(s.ss_item_sk) AS total_sales,
        SUM(cte.ss_net_paid) AS total_net_paid,
        AVG(cte.ss_sales_price) AS average_sales_price,
        SUM(cte.discount_amount) AS total_discount
    FROM 
        item i
    LEFT JOIN 
        Sales_CTE cte ON i.i_item_sk = cte.ss_item_sk
    GROUP BY 
        i.i_item_id
),
Customer_Summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        SUM(ss.ss_net_paid) AS total_spent,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < 1990 
        AND cd.cd_marital_status = 'M'
    GROUP BY
        c.c_customer_id, 
        cd.cd_gender
),
Final_Report AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        is_.total_sales,
        is_.total_net_paid,
        is_.total_discount,
        cs.purchase_count,
        cs.total_spent,
        cs.last_purchase_date
    FROM 
        Item_Summary is_
    FULL OUTER JOIN 
        Customer_Summary cs ON is_.i_item_id = cs.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.cd_gender,
    COALESCE(fr.total_sales, 0) AS total_sales,
    COALESCE(fr.total_net_paid, 0) AS total_net_paid,
    COALESCE(fr.total_discount, 0) AS total_discount,
    COALESCE(fr.purchase_count, 0) AS purchase_count,
    COALESCE(fr.total_spent, 0) AS total_spent,
    fr.last_purchase_date
FROM 
    Final_Report fr
ORDER BY 
    total_spent DESC, 
    purchase_count DESC;
