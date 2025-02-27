
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year < (CURRENT_YEAR - 30) -- Customers older than 30 years
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        w.web_site_name,
        r.total_quantity,
        r.total_net_profit
    FROM 
        RankedSales r
    JOIN 
        web_site w ON r.web_site_sk = w.web_site_sk
    WHERE 
        r.profit_rank <= 5 -- Top 5 websites by profit
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        CASE 
            WHEN ws.ws_ext_discount_amt > 0 THEN 'Discounted' 
            ELSE 'Full Price' 
        END AS price_category
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 50 -- Only considering items sold over $50
),
AggregatedSales AS (
    SELECT 
        sd.price_category,
        COUNT(*) AS total_sales,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_revenue
    FROM 
        SalesDetails sd
    GROUP BY 
        sd.price_category
)
SELECT 
    tw.web_site_name,
    a.price_category,
    a.total_sales,
    a.total_quantity,
    a.total_revenue
FROM 
    TopWebSites tw
JOIN 
    AggregatedSales a ON a.total_sales IS NOT NULL
ORDER BY 
    tw.web_site_name, a.price_category;
