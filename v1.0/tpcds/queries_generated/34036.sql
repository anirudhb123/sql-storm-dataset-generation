
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        ws_sales_price * SUM(ws_quantity) AS total_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2450001 AND 2450599
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        cs_sales_price * SUM(cs_quantity) AS total_sales
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk BETWEEN 2450001 AND 2450599
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_quantity) > 50
), 
TotalSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales
    FROM 
        SalesCTE s
    INNER JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10 AND 
        i.i_brand IN (SELECT DISTINCT i_brand 
                      FROM item 
                      WHERE i_category = 'Electronics')
), 
SalesWithRank AS (
    SELECT 
        ts.ws_item_sk, 
        ts.total_quantity,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
)

SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    swr.total_quantity, 
    swr.total_sales, 
    swr.sales_rank,
    COALESCE(ca.ca_city, 'Unknown') AS shipping_city,
    d.d_date AS report_date,
    CASE 
        WHEN swr.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller' 
    END AS seller_category
FROM 
    SalesWithRank swr
LEFT JOIN 
    item i ON swr.ws_item_sk = i.i_item_sk
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory WHERE inv_item_sk = i.i_item_sk)
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk = (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_purchase_estimate > 5000 LIMIT 1))
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM NOW()))
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    swr.sales_rank;
