
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
        SUM(ss.ss_sales_price) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_sales_price) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender
),
PopularItems AS (
    SELECT 
        ss.ss_item_sk,
        COUNT(ss.ss_item_sk) AS purchase_count,
        SUM(ss.ss_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY COUNT(ss.ss_item_sk) DESC) AS item_rank
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_returning_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.total_spent,
    rc.sales_count,
    pi.total_revenue AS item_revenue,
    cr.total_returns AS returns,
    CASE 
        WHEN rc.total_spent > 500 THEN 'High Value'
        WHEN rc.total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN pi.item_rank <= 10 THEN 'Top Item'
        ELSE 'Regular Item'
    END AS item_category
FROM 
    RankedCustomers rc
LEFT JOIN 
    PopularItems pi ON pi.ss_item_sk = rc.c_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cr.cr_returning_customer_sk = rc.c_customer_sk
WHERE 
    rc.gender_rank = 1
    AND (rc.total_spent IS NOT NULL OR cr.total_returns > 0)
    AND EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_store_sk = (
            SELECT ss.ss_store_sk 
            FROM store_sales ss 
            WHERE ss.ss_customer_sk = rc.c_customer_sk 
            LIMIT 1
        ) 
        AND s.s_country IS NOT NULL
    )
ORDER BY 
    rc.total_spent DESC, rc.sales_count ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
