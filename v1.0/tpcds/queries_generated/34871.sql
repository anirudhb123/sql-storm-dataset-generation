
WITH RECURSIVE YearlySales AS (
    SELECT 
        d_year AS year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk 
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        year - 1,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk 
    WHERE 
        d_year = (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        year
    HAVING 
        year > 0
),
SalesRanked AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS item_profit,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
),
FilteredAddresses AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS address_count
    FROM 
        customer_address 
    LEFT JOIN 
        customer ON c_current_addr_sk = ca_address_sk
    GROUP BY 
        ca_state
    HAVING 
        address_count > 10
)
SELECT 
    y.year,
    a.ca_state AS state,
    COALESCE(s.item_profit, 0) AS total_item_profit,
    SUM(a.address_count) OVER (ORDER BY y.year) AS running_address_count
FROM 
    YearlySales y
LEFT JOIN 
    FilteredAddresses a ON a.ca_state IS NOT NULL
LEFT JOIN 
    SalesRanked s ON s.profit_rank = 1
WHERE 
    y.total_sales > 10000
ORDER BY 
    y.year, a.ca_state;
