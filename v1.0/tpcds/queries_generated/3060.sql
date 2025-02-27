
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(ranked.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ranked.ws_order_number) AS total_orders
    FROM 
        RankedSales AS ranked
    JOIN 
        item ON ranked.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
),
TopItems AS (
    SELECT 
        *,
        NTILE(10) OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ci.c_email_address,
    ti.i_product_name,
    ti.total_sales,
    ti.total_orders
FROM 
    customer AS ci
JOIN 
    web_sales AS ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    TopItems AS ti ON ws.ws_item_sk = ti.ws_item_sk
WHERE 
    ti.sales_rank = 1
    AND ci.c_email_address IS NOT NULL
ORDER BY 
    ti.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
