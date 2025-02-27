
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        MAX(rs.ws_ext_discount_amt) AS max_discount
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
SalesWithDiscounts AS (
    SELECT 
        as.w_item_sk,
        as.total_sales,
        as.order_count,
        CASE 
            WHEN as.max_discount IS NULL THEN 0 
            ELSE as.max_discount 
        END AS effective_discount
    FROM 
        AggregatedSales as
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COALESCE(MAX(sw.total_sales), 0) AS max_sales,
    AVG(sw.total_sales) AS avg_sales,
    COUNT(DISTINCT sw.order_count) AS distinct_order_count,
    STRING_AGG(DISTINCT i.i_product_name) AS product_names,
    SUM(NULLIF(i.i_current_price, 0)) / NULLIF(SUM(i.i_current_price) OVER (PARTITION BY ca.ca_city), 0) AS price_ratio
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT ws_bill_customer_sk, total_sales, order_count
     FROM SalesWithDiscounts
     WHERE effective_discount > 0) sw ON c.c_customer_sk = sw.ws_bill_customer_sk
JOIN 
    item i ON sw.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('NY', 'CA') AND 
    (c.c_birth_year BETWEEN 1970 AND 1990 OR c.c_birth_country IS NULL)
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    COUNT(DISTINCT i.i_item_sk) > 2
ORDER BY 
    max_sales DESC NULLS LAST;
