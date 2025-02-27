
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        total_quantity + cs_quantity,
        total_sales + cs_ext_sales_price
    FROM 
        SalesCTE
    JOIN 
        catalog_sales ON SalesCTE.ws_item_sk = catalog_sales.cs_item_sk
    WHERE 
        SalesCTE.ws_sold_date_sk < catalog_sales.cs_sold_date_sk
), CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
), AddressSales AS (
    SELECT 
        ca.ca_address_id,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales_per_customer
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
    GROUP BY 
        ca.ca_address_id
)
SELECT 
    a.ca_address_id,
    a.customer_count,
    a.avg_sales_per_customer,
    ROW_NUMBER() OVER (ORDER BY a.avg_sales_per_customer DESC) AS sales_rank
FROM 
    AddressSales a
WHERE 
    a.avg_sales_per_customer IS NOT NULL
    AND a.customer_count > 0
ORDER BY 
    a.avg_sales_per_customer DESC;

WITH ItemStats AS (
    SELECT 
        i.i_item_id,
        i.i_current_price,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_current_price
)
SELECT 
    i.i_item_id,
    i.i_current_price,
    i.total_sold,
    i.total_profit,
    CASE 
        WHEN i.total_profit > 0 THEN 'Profitable'
        WHEN i.total_sold = 0 THEN 'Unsold'
        ELSE 'Loss'
    END AS profit_status
FROM 
    ItemStats i
WHERE 
    i.total_sold > 100
ORDER BY 
    i.total_profit DESC 
LIMIT 10;

SELECT 
    d.d_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
FROM 
    store_sales ss
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = (SELECT MAX(d_year) FROM date_dim)
GROUP BY 
    d.d_year;
