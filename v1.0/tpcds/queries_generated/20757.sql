
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        CASE 
            WHEN r.price_rank = 1 THEN 'Top Sale'
            ELSE 'Other Sale'
        END AS sale_type
    FROM 
        RankedSales r
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_spend,
        d.d_year,
        (SELECT COUNT(DISTINCT ws_order_number) 
         FROM web_sales ws 
         WHERE ws_bill_customer_sk = c.c_customer_sk) AS order_count,
        CASE 
            WHEN COUNT(DISTINCT ws_order_number) > 5 THEN 'High Engagement'
            WHEN COUNT(DISTINCT ws_order_number) BETWEEN 2 AND 5 THEN 'Medium Engagement'
            ELSE 'Low Engagement'
        END AS engagement_level
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        item item
    JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_id
    HAVING 
        total_quantity > 100
)
SELECT 
    ca.ca_city,
    SUM(CASE WHEN ta.sale_type = 'Top Sale' THEN 1 ELSE 0 END) AS top_sales_count,
    SUM(CASE WHEN ca.engagement_level = 'High Engagement' THEN cs.total_revenue ELSE 0 END) AS high_engagement_revenue,
    COUNT(DISTINCT ca.c_customer_sk) AS total_customers,
    MAX(IFNULL(cs.total_revenue, 0)) as max_revenue,
    MAX(cs.total_quantity) AS max_quantity_sold,
    COUNT(DISTINCT cs.item.i_item_id) AS unique_items_sold
FROM 
    customer_analysis ca
LEFT JOIN 
    TopSales ta ON ta.ws_order_number IN (SELECT ws_order_number FROM web_sales ws WHERE ws_bill_customer_sk = ca.c_customer_sk)
LEFT JOIN 
    SalesSummary cs ON cs.total_revenue BETWEEN 1000 AND 5000
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = ca.c_current_addr_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    top_sales_count DESC, high_engagement_revenue DESC
LIMIT 10;
