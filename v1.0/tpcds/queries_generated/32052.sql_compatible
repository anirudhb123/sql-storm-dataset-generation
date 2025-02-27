
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451500 AND 2451540
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        SalesCTE s ON cs.cs_item_sk = s.ws_item_sk
    GROUP BY 
        cs.cs_item_sk
),
RankedSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_net_profit,
        RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
    FROM 
        SalesCTE s
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        CASE 
            WHEN COALESCE(s.total_net_profit, 0) = 0 THEN 'No Sales'
            ELSE 'Active Sales'
        END AS sales_status
    FROM 
        item i
    LEFT JOIN 
        RankedSales s ON i.i_item_sk = s.ws_item_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    d.d_year,
    COUNT(DISTINCT id.i_item_id) AS item_count,
    SUM(id.total_net_profit) AS total_net_profit,
    ROUND(AVG(id.total_quantity), 2) AS avg_quantity,
    MAX(rs.profit_rank) AS max_profit_rank
FROM 
    customer_address a
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    ItemDetails id ON c.c_customer_sk = id.i_item_id
JOIN 
    date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = id.i_item_id
WHERE 
    a.ca_state IS NOT NULL 
    AND d.d_year = 2023
GROUP BY 
    a.ca_city, a.ca_state, d.d_year
HAVING 
    SUM(id.total_net_profit) > 10000
ORDER BY 
    total_net_profit DESC;
