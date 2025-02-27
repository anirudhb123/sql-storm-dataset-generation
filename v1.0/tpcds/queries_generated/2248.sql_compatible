
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459208 AND 2459229
), TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS customer_total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
), HighNetProfit AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_profit,
        ts.total_sales,
        cs.customer_total_sales
    FROM 
        RankedSales rs
    JOIN 
        TotalSales ts ON rs.ws_item_sk = ts.ws_item_sk
    JOIN 
        CustomerSales cs ON rs.ws_order_number = cs.c_customer_id
    WHERE 
        rs.sales_rank = 1 AND rs.ws_net_profit > 100
)
SELECT 
    hi.ws_item_sk,
    hi.ws_order_number,
    hi.ws_net_profit,
    hi.total_sales,
    hi.customer_total_sales,
    CASE 
        WHEN hi.customer_total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status
FROM 
    HighNetProfit hi
ORDER BY 
    hi.ws_net_profit DESC;
