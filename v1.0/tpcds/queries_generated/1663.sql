
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales AS ws
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
CustomerProfits AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT CASE WHEN ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales) THEN ws_order_number END) AS above_average_sales
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
ReturnsSummary AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(*) AS returns_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns AS cr
    GROUP BY 
        cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.order_count,
        cs.above_average_sales,
        rs.ws_item_sk,
        COALESCE(rs.rank, 0) AS sales_rank,
        COALESCE(rs.ws_sales_price, 0) AS item_sales_price,
        COALESCE(rs.web_site_sk, 'N/A') AS website_id,
        COALESCE(rs.ws_net_profit, 0) AS item_profit,
        COALESCE(rs.ws_item_sk IS NULL, 'No Sales') AS sales_status,
        COALESCE(r.returns_count, 0) AS item_returns,
        COALESCE(r.total_return_amount, 0.00) AS total_returns
    FROM 
        CustomerProfits AS cs
    LEFT JOIN 
        RankedSales AS rs ON cs.order_count > 0
    LEFT JOIN 
        ReturnsSummary AS r ON r.cr_item_sk = rs.ws_item_sk
    WHERE 
        cs.total_profit > 1000
        AND (r.returns_count IS NULL OR r.returns_count < 5) 
        OR (cs.above_average_sales > 2)
)
SELECT 
    *,
    CASE 
        WHEN total_profit > 5000 THEN 'High'
        WHEN total_profit BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    FinalReport
ORDER BY 
    total_profit DESC, order_count DESC;
