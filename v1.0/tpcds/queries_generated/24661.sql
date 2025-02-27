
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(CAST(ws.ws_net_paid AS DECIMAL(15, 2)), 0) AS net_paid,
        (ws.ws_sales_price * ws.ws_quantity) - COALESCE(ws.ws_ext_discount_amt, 0) AS total_sales,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'Unknown Price' 
            ELSE NULL 
        END AS price_status,
        CASE 
            WHEN ws.ws_quantity = 0 THEN 'Zero Quantity' 
            ELSE NULL 
        END AS quantity_status
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
AggregatedSales AS (
    SELECT 
        item.sk AS item_sk,
        SUM(total_sales) AS total_revenue,
        COUNT(DISTINCT order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(CASE WHEN price_status IS NOT NULL THEN 1 ELSE 0 END) AS unknown_price_count
    FROM 
        RankedSales rst
    LEFT JOIN 
        item item ON rst.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.sk
)
SELECT 
    item.i_item_id,
    item.i_product_name,
    ag.total_revenue,
    ag.total_orders,
    ag.avg_sales_price,
    ag.unknown_price_count,
    (SELECT COUNT(*) FROM customer WHERE c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = item.i_item_sk)) AS customer_count,
    (SELECT COALESCE(MIN(ws_net_paid), 0) FROM web_sales WHERE ws_item_sk = item.i_item_sk AND ws_net_paid < (SELECT AVG(ws_net_paid) FROM web_sales)) AS min_below_avg_net_paid
FROM 
    item
JOIN 
    AggregatedSales ag ON item.i_item_sk = ag.item_sk
WHERE 
    ag.total_revenue > (SELECT AVG(total_revenue) FROM AggregatedSales)
ORDER BY 
    ag.total_revenue DESC
LIMIT 10;
