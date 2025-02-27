
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
BestSellingItems AS (
    SELECT 
        a.i_item_id,
        a.i_item_desc,
        b.total_sold
    FROM 
        item a
    JOIN 
        (SELECT 
            ws_item_sk, 
            SUM(ws_quantity) AS total_sold
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk) b 
    ON a.i_item_sk = b.ws_item_sk
)
SELECT 
    c.c_city,
    SUM(st.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT st.ss_ticket_number) AS total_orders,
    COUNT(DISTINCT s.s_store_id) AS num_stores,
    COALESCE(b.total_sold, 0) AS best_selling_item
FROM 
    store_sales st
JOIN 
    store s ON st.ss_store_sk = s.s_store_sk
JOIN 
    customer c ON st.ss_customer_sk = c.c_customer_sk
LEFT JOIN 
    BestSellingItems b ON b.total_sold = (
        SELECT 
            MAX(total_sold)
        FROM 
            BestSellingItems
    )
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
    AND s.s_state = 'CA'
GROUP BY 
    c.c_city
HAVING 
    SUM(st.ss_net_profit) > 5000
ORDER BY 
    total_net_profit DESC
LIMIT 10;
