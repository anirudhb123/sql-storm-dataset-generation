
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS total_orders
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ri.ws_sales_price) AS total_revenue
    FROM 
        web_sales ri
    JOIN 
        RankedSales r ON ri.ws_item_sk = r.ws_item_sk AND r.price_rank = 1
    WHERE 
        ri.ws_ship_date_sk > (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_date = (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2023)
        )
    GROUP BY 
        ri.ws_item_sk
),
FinalOutput AS (
    SELECT 
        a.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(COALESCE(cr.total_returned, 0)) AS total_returns,
        SUM(obi.total_sales) AS total_item_sales,
        SUM(obi.total_revenue) AS total_item_revenue,
        CASE 
            WHEN COUNT(DISTINCT c.c_customer_sk) > 0 THEN SUM(obi.total_revenue) / COUNT(DISTINCT c.c_customer_sk)
            ELSE 0
        END AS average_revenue_per_customer
    FROM 
        customer c
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        TopItems obi ON EXISTS 
        (
            SELECT 1 
            FROM store_sales ss 
            WHERE ss.ss_customer_sk = c.c_customer_sk 
              AND ss.ss_item_sk = obi.ws_item_sk
        )
    GROUP BY 
        a.ca_city
)
SELECT 
    ca_city,
    AVG(CASE WHEN total_returns > 0 THEN total_returns ELSE NULL END) AS avg_returns_per_city,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_item_revenue) AS median_revenue,
    ARRAY_AGG(DISTINCT total_item_sales) AS distinct_sales_counts,
    STRING_AGG(DISTINCT CONCAT('City:', ca_city, ' Revenue:', total_item_revenue), '; ') AS city_revenue_summary
FROM 
    FinalOutput
WHERE 
    average_revenue_per_customer > 100
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT ca_city) <= 20
ORDER BY 
    ca_city;
