
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN 1000 AND 1500
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_category,
        item.i_current_price,
        sales.total_quantity_sold,
        sales.total_sales
    FROM 
        item
    JOIN 
        RankedSales sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.sales_rank <= 10
),
CustomerAddresses AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
SalesSummary AS (
    SELECT 
        ca.ca_state,
        SUM(ts.total_sales) AS total_sales_by_state,
        SUM(ts.total_quantity_sold) AS total_quantity_by_state,
        AVG(ts.total_sales) AS avg_sales_per_item 
    FROM 
        TopItems ts
    JOIN 
        customer_address ca ON ts.i_item_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    ss.ca_state,
    ss.total_sales_by_state,
    ss.total_quantity_by_state,
    ss.avg_sales_per_item,
    COALESCE(ca.num_customers, 0) AS total_customers
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerAddresses ca ON ss.ca_state = ca.ca_state
ORDER BY 
    ss.total_sales_by_state DESC, ss.ca_state
LIMIT 50
OFFSET 0;
