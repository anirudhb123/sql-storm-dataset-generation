
WITH RECURSIVE top_selling_items AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 10 -- Only consider items sold more than 10 times
), 
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(p.p_discount_active, 'N') AS is_discounted
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk AND p.p_end_date_sk > CAST(CURRENT_DATE AS integer)
), 
sales_summary AS (
    SELECT 
        s.ss_sold_date_sk,
        SUM(s.ss_net_paid) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS number_of_transactions,
        AVG(s.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales s
    JOIN 
        store st ON s.ss_store_sk = st.s_store_sk
    WHERE 
        st.s_state = 'CA' -- Focus on California stores
    GROUP BY 
        s.ss_sold_date_sk
)
SELECT 
    d.d_date AS sales_date,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.number_of_transactions, 0) AS number_of_transactions,
    COALESCE(ss.avg_sales_price, 0) AS avg_sales_price,
    i.i_product_name,
    i.i_current_price,
    CASE 
        WHEN i.is_discounted = 'Y' THEN 'Yes'
        ELSE 'No'
    END AS discounted
FROM 
    date_dim d
LEFT JOIN 
    sales_summary ss ON d.d_date_sk = ss.ss_sold_date_sk
JOIN 
    top_selling_items tsi ON tsi.ws_item_sk IN (SELECT i_item_sk FROM item_details)
JOIN 
    item_details i ON tsi.ws_item_sk = i.i_item_sk
WHERE 
    d.d_date BETWEEN DATEADD(month, -6, CURRENT_DATE) AND CURRENT_DATE -- Last 6 months
ORDER BY 
    total_sales DESC, 
    sales_date DESC
LIMIT 10;
