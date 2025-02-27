
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
),
HighValueItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        item.i_brand,
        SUM(sales.ws_ext_sales_price) AS total_sales
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 10
    GROUP BY 
        item.i_item_sk, item.i_item_desc, item.i_brand
),
TopBrands AS (
    SELECT 
        hvi.i_brand,
        SUM(hvi.total_sales) AS brand_sales
    FROM 
        HighValueItems hvi
    GROUP BY 
        hvi.i_brand
    ORDER BY 
        brand_sales DESC
    LIMIT 5
)
SELECT 
    tb.i_brand,
    tb.brand_sales,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count
FROM 
    TopBrands tb
LEFT JOIN 
    web_sales ws ON ws.ws_item_sk IN (SELECT i_item_sk FROM HighValueItems WHERE i_brand = tb.i_brand)
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    tb.i_brand, tb.brand_sales, ca.ca_city, ca.ca_state
HAVING 
    customer_count > 0
ORDER BY 
    tb.brand_sales DESC;
