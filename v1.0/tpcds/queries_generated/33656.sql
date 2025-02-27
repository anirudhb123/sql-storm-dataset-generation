
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
Top_Profitable_Items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(sales.total_profit) AS aggregated_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(sales.total_profit) DESC) AS item_rank
    FROM 
        Sales_CTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
    HAVING 
        SUM(sales.total_profit) > 10000
),
Store_Stats AS (
    SELECT 
        st.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store st
    LEFT JOIN 
        store_sales ss ON st.s_store_sk = ss.ss_store_sk
    GROUP BY 
        st.s_store_id
)
SELECT 
    coalesce(ts.item_rank, 0) AS top_item_rank,
    ts.i_item_id,
    ts.i_item_desc,
    ss.total_sales,
    ss.total_store_profit,
    CASE 
        WHEN ss.total_store_profit IS NULL THEN 'No Sales' 
        ELSE 'Sales Present' 
    END AS sales_status,
    DATEADD(DAY, -1 * (EXTRACT(DOW FROM CURRENT_DATE) + 6) % 7, CURRENT_DATE) AS last_sunday,
    (SELECT COUNT(DISTINCT customer.c_customer_sk) 
     FROM customer 
     WHERE customer.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE)
     AND customer.c_birth_day = EXTRACT(DAY FROM CURRENT_DATE)) AS birthday_customers_count
FROM 
    Top_Profitable_Items ts
LEFT JOIN 
    Store_Stats ss ON ts.i_item_id = ss.total_store_profit
WHERE 
    ts.item_rank <= 10
ORDER BY 
    ts.aggregated_profit DESC;
