
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.store_sk,
        SUM(ss.quantity) AS total_quantity,
        SUM(ss.net_paid) AS total_sales
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                           AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ss.sold_date_sk, ss.item_sk, ss.store_sk
    UNION ALL
    SELECT 
        scte.sold_date_sk,
        scte.item_sk,
        scte.store_sk,
        SUM(scte.total_quantity) AS total_quantity,
        SUM(scte.total_sales) AS total_sales
    FROM 
        SalesCTE scte
    JOIN 
        store_sales ss ON ss.item_sk = scte.item_sk AND ss.store_sk = scte.store_sk
    WHERE 
        ss.sold_date_sk < scte.sold_date_sk
    GROUP BY 
        scte.sold_date_sk, scte.item_sk, scte.store_sk
),
AggregateSales AS (
    SELECT 
        scte.store_sk,
        SUM(scte.total_quantity) AS total_quantity_sold,
        SUM(scte.total_sales) AS total_sales,
        COUNT(DISTINCT scte.item_sk) AS unique_items_sold
    FROM 
        SalesCTE scte
    GROUP BY 
        scte.store_sk
),
TopStores AS (
    SELECT 
        a.store_sk,
        a.total_quantity_sold,
        a.total_sales,
        ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS sales_rank
    FROM 
        AggregateSales a
)
SELECT 
    ts.store_sk,
    ts.total_quantity_sold,
    ts.total_sales,
    ts.sales_rank,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopStores ts
LEFT JOIN 
    store st ON ts.store_sk = st.s_store_sk
LEFT JOIN 
    customer_address ca ON st.s_store_sk = ca.ca_address_sk
WHERE 
    (ts.sales_rank <= 10 OR ts.total_sales IS NULL)
    AND (ca.ca_state = 'CA' OR ca.ca_country = 'USA')
ORDER BY 
    ts.total_sales DESC;
