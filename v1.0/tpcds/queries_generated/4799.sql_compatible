
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND i.i_current_price > 0
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_order_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.avg_order_quantity,
        cs.total_net_profit
    FROM 
        CustomerStatistics cs
    WHERE 
        cs.total_net_profit > 1000
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count, 
    AVG(hvc.avg_order_quantity) AS avg_quantity_per_order,
    SUM(hvc.total_net_profit) AS total_net_profit_by_city,
    (SELECT 
        AVG(total_sales) 
     FROM 
        RankedSales rs 
     WHERE 
        rs.web_site_sk IN (SELECT DISTINCT w.w_warehouse_sk FROM warehouse w WHERE w.w_country = 'USA')
    ) AS avg_website_sales_in_usa
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    HighValueCustomers hvc ON hvc.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT hvc.c_customer_sk) > 5
ORDER BY 
    total_net_profit_by_city DESC;
