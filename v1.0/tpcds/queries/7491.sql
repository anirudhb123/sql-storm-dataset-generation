
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, 
        ws_item_sk
),
PopularItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        SUM(rs.total_sales) AS overall_sales,
        COUNT(DISTINCT rs.ws_bill_customer_sk) AS distinct_customers
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        rs.ws_item_sk, 
        i.i_item_desc
),
ItemDetails AS (
    SELECT 
        pi.ws_item_sk,
        pi.i_item_desc,
        pi.overall_sales,
        pi.distinct_customers,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        PopularItems pi
    JOIN 
        customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = pi.ws_item_sk LIMIT 1)
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    id.i_item_desc,
    id.overall_sales,
    id.distinct_customers,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    ItemDetails id
JOIN 
    web_sales ws ON id.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    id.i_item_desc, 
    id.overall_sales, 
    id.distinct_customers
ORDER BY 
    total_profit DESC
LIMIT 50;
