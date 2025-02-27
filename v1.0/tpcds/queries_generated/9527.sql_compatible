
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA' 
        AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2) 
        AND ws.ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY 
        ws.web_site_sk, 
        ws_order_number
),
TopSales AS (
    SELECT 
        r.web_site_sk, 
        r.total_sales, 
        r.unique_customers, 
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS top_rank
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    t.web_site_sk,
    SUM(t.total_sales) AS cumulative_sales,
    AVG(t.unique_customers) AS avg_unique_customers
FROM 
    TopSales t
GROUP BY 
    t.web_site_sk
ORDER BY 
    cumulative_sales DESC;
