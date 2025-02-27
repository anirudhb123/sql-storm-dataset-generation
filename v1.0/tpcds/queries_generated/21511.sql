
WITH RankedSales AS (
    SELECT 
        ws_c.shop_id,
        ws_ws.item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_c.shop_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        ws_c.shop_id, ws_ws.item_sk
),
HighValueSales AS (
    SELECT 
        r.shop_id,
        r.item_sk,
        r.total_sales,
        CASE 
            WHEN r.total_sales > (SELECT AVG(total_sales) FROM RankedSales) THEN 'Above Average'
            WHEN r.total_sales IS NULL THEN 'No Sales'
            ELSE 'Below Average'
        END AS sales_status
    FROM 
        RankedSales r
)
SELECT 
    h.shop_id,
    h.item_sk,
    h.total_sales,
    h.sales_status,
    COALESCE(m.sales_count, 0) AS monthly_sales_count,
    CASE 
        WHEN h.sales_status = 'Below Average' THEN 'Seek Promotion'
        ELSE 'Maintain'
    END AS action_recommendation
FROM 
    HighValueSales h
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk, COUNT(ws_order_number) AS sales_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_bill_customer_sk
) m ON h.shop_id = m.ws_bill_customer_sk
WHERE 
    h.sales_rank <= 10
ORDER BY 
    h.total_sales DESC;
