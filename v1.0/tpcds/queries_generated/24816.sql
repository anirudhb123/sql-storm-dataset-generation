
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 100.00
), SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_profit,
        MAX(rs.ws_sales_price) AS max_sales_price
    FROM 
        RecursiveSales rs
    GROUP BY 
        rs.ws_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        CASE 
            WHEN MAX(rs.total_profit) IS NULL THEN 'No Sales'
            WHEN MAX(rs.total_profit) > 1000 THEN 'High Profit'
            ELSE 'Low Profit' 
        END AS profit_category
    FROM 
        item i
    LEFT JOIN 
        SalesSummary rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
), StateWiseCount AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(COALESCE(ss.total_quantity, 0)) AS nationwide_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ca_state
)

SELECT 
    id.i_item_desc,
    id.profit_category,
    swc.ca_state,
    swc.customer_count,
    swc.nationwide_quantity,
    CASE 
        WHEN swc.customer_count > 0 
            THEN ROUND((swc.nationwide_quantity * 1.0 / swc.customer_count), 2)
        ELSE 0 
    END AS avg_quantity_per_customer
FROM 
    ItemDetails id
JOIN 
    StateWiseCount swc ON 1 = 1
WHERE 
    id.profit_category != 'No Sales'
ORDER BY 
    swc.nationwide_quantity DESC, id.i_item_desc ASC
LIMIT 50;
