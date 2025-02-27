
WITH ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid_inc_tax) AS total_net_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), CombinedSales AS (
    SELECT 
        is.ws_item_sk,
        is.total_quantity AS web_quantity,
        is.total_sales AS web_sales,
        ss.total_quantity AS store_quantity,
        ss.total_net_sales AS store_net_sales,
        ss.total_transactions
    FROM 
        ItemSales is
    FULL OUTER JOIN 
        StoreSales ss ON is.ws_item_sk = ss.ss_item_sk
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    COALESCE(cs.web_quantity, 0) AS web_quantity,
    COALESCE(cs.web_sales, 0) AS web_sales,
    COALESCE(cs.store_quantity, 0) AS store_quantity,
    COALESCE(cs.store_net_sales, 0) AS store_net_sales,
    COALESCE(cs.total_transactions, 0) AS total_transactions,
    CASE 
        WHEN COALESCE(cs.web_sales, 0) > COALESCE(cs.store_net_sales, 0) 
        THEN 'Web Dominant'
        WHEN COALESCE(cs.web_sales, 0) < COALESCE(cs.store_net_sales, 0) 
        THEN 'Store Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance,
    (SELECT COUNT(*) 
     FROM customer c
     WHERE c.c_current_cdemo_sk IS NOT NULL AND 
           c.c_birth_year > (SELECT MIN(cd_birth_year) FROM customer_demographics)
           AND c.c_preferred_cust_flag = 'Y'
           HAVING COUNT(c.c_customer_sk) > 10) AS preferred_customers_count,
    CASE 
        WHEN EXISTS (SELECT 1 
                     FROM promotion p 
                     WHERE p.p_discount_active = 'Y' AND 
                           p.p_start_date_sk = (SELECT MAX(p2.p_start_date_sk) 
                                                FROM promotion p2 
                                                WHERE p2.p_item_sk = ci.i_item_sk) 
                     ) 
        THEN 'Promo Available'
        ELSE 'No Active Promo'
    END AS promotion_status
FROM 
    item ci
LEFT JOIN 
    CombinedSales cs ON ci.i_item_sk = cs.ws_item_sk
WHERE 
    ci.i_current_price > 0 AND 
    ci.i_item_desc IS NOT NULL AND 
    ((cs.web_quantity > 0 AND cs.store_quantity = 0) OR 
     (cs.store_quantity > 0 AND cs.web_quantity = 0))
ORDER BY 
    total_net_sales DESC,
    sales_dominance,
    ci.i_item_id;
