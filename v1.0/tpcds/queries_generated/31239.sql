
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        ss_quantity, 
        ss_sales_price,
        ss_ext_sales_price,
        ss_extensions as sales_extras,
        1 as level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.quantity,
        ss.sales_price,
        ss.ext_sales_price,
        ss.extensions,
        cte.level + 1
    FROM 
        store_sales ss
    INNER JOIN 
        SalesCTE cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE 
        cte.level < 5
),
AggregatedSales AS (
    SELECT
        item.i_item_id,
        SUM(cte.ss_quantity) AS total_quantity,
        SUM(cte.ss_ext_sales_price) AS total_sales,
        STRING_AGG(DISTINCT item.i_product_name) AS product_names,
        item.i_current_price AS current_price
    FROM 
        SalesCTE cte
    JOIN 
        item ON cte.ss_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_current_price
)
SELECT 
    ca.ca_city,
    SUM(agg.total_sales) AS total_sales_by_city,
    COUNT(DISTINCT ca.ca_address_sk) AS number_of_addresses,
    (SELECT COUNT(*)
     FROM customer 
     WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address)) AS total_customers,
    CASE 
        WHEN COUNT(DISTINCT ca.ca_address_sk) > 5 THEN 'High Density'
        WHEN COUNT(DISTINCT ca.ca_address_sk) BETWEEN 3 AND 5 THEN 'Medium Density'
        ELSE 'Low Density' 
    END AS address_density
FROM 
    customer_address ca
LEFT JOIN 
    AggregatedSales agg ON ca.ca_city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = agg.ca_address_sk)
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales_by_city DESC
LIMIT 10;
