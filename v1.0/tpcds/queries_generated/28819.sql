
WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc, i.i_brand
),
TopItems AS (
    SELECT 
        r.i_item_id,
        r.i_item_desc,
        r.i_brand,
        r.order_count,
        r.total_sales
    FROM 
        RankedItems r
    WHERE 
        r.rank <= 5
)
SELECT 
    ca_state,
    COUNT(DISTINCT ci.c_customer_id) AS customer_count,
    SUM(ti.total_sales) AS sales_sum
FROM 
    TopItems ti
JOIN 
    web_site ws ON ws.web_site_sk = ti.ws_web_site_sk
JOIN 
    customer ci ON ci.c_customer_sk = ws.web_site_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = ci.c_current_addr_sk
GROUP BY 
    ca_state
ORDER BY 
    sales_sum DESC;
