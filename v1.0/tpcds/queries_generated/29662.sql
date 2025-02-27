
WITH CustomerCount AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c_customer_sk) AS customer_count 
    FROM 
        customer_address ca 
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk 
    GROUP BY 
        ca_state
), 
ProductAnalysis AS (
    SELECT 
        i_category, 
        COUNT(DISTINCT ws_order_number) AS total_orders, 
        SUM(ws_sales_price) AS total_revenue 
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    GROUP BY 
        i_category
), 
TopProducts AS (
    SELECT 
        i_item_id, 
        i_item_desc, 
        i_category, 
        RANK() OVER (PARTITION BY i_category ORDER BY total_revenue DESC) AS revenue_rank 
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    GROUP BY 
        i_item_id, i_item_desc, i_category
)
SELECT 
    cc.ca_state AS state, 
    cc.customer_count, 
    pa.i_category, 
    pa.total_orders, 
    pa.total_revenue, 
    tp.i_item_id, 
    tp.i_item_desc 
FROM 
    CustomerCount cc 
JOIN 
    ProductAnalysis pa ON cc.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk IN (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cc.customer_count)) 
JOIN 
    TopProducts tp ON tp.revenue_rank <= 5 
ORDER BY 
    cc.ca_state, pa.total_revenue DESC;
