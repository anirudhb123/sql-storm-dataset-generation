
WITH RECURSIVE SalesTrend AS (
    SELECT 
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY ss_sold_date_sk) AS date_rank
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk
    HAVING 
        SUM(ss_net_profit) > 1000
    UNION ALL
    SELECT 
        st.ss_sold_date_sk,
        st.total_net_profit + COALESCE(promotion.p_discount_active, 0) AS total_net_profit,
        st.date_rank
    FROM 
        SalesTrend st
    LEFT JOIN 
        promotion ON promotion.p_start_date_sk <= st.ss_sold_date_sk 
                  AND promotion.p_end_date_sk >= st.ss_sold_date_sk
)
SELECT 
    DATE_DIM.d_year,
    COALESCE(SUM(SalesTrend.total_net_profit), 0) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS total_orders,
    MAX(item.i_current_price) AS max_price,
    MIN(item.i_current_price) AS min_price,
    AVG(item.i_current_price) AS avg_price
FROM 
    date_dim DATE_DIM
LEFT JOIN 
    store_sales ON DATE_DIM.d_date_sk = store_sales.ss_sold_date_sk
LEFT JOIN 
    SalesTrend ON DATE_DIM.d_date_sk = SalesTrend.ss_sold_date_sk
JOIN 
    item ON item.i_item_sk = store_sales.ss_item_sk
LEFT JOIN 
    customer_address ON customer_address.ca_address_sk = store_sales.ss_addr_sk
WHERE 
    DATE_DIM.d_year = 2023 
    AND (customer_address.ca_state IS NULL OR customer_address.ca_state = 'CA')
GROUP BY 
    DATE_DIM.d_year
HAVING 
    total_profit > 5000 
ORDER BY 
    total_profit DESC
LIMIT 10;
