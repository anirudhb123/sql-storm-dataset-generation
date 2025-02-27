
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT 
        sr_returning_customer_sk, 
        SUM(cr_return_amount) * -1 AS total_profit,
        COUNT(cr_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS rank
    FROM 
        catalog_returns
    GROUP BY 
        sr_returning_customer_sk
    HAVING 
        SUM(cr_return_amount) < -500
),
expected_revenue AS (
    SELECT 
        ca.ca_address_sk,
        SUM(ws_ext_sales_price) AS potential_sales
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_address_sk
),
final_report AS (
    SELECT 
        sh.customer_sk, 
        sh.total_profit, 
        sh.order_count, 
        er.potential_sales,
        CASE 
            WHEN sh.total_profit IS NULL THEN 'Customer Without Sales'
            WHEN sh.total_profit >= 1000 THEN 'High Profit'
            ELSE 'Moderate Profit'
        END AS profit_category
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        expected_revenue er ON sh.customer_sk = er.ca_address_sk
)
SELECT 
    fr.customer_sk, 
    fr.total_profit, 
    fr.order_count, 
    fr.potential_sales,
    fr.profit_category,
    COALESCE(fr.potential_sales, 0) - COALESCE(fr.total_profit, 0) AS revenue_difference,
    CURRENT_TIMESTAMP AS report_generated_at
FROM 
    final_report fr
WHERE 
    fr.profit_category <> 'Customer Without Sales'
ORDER BY 
    fr.total_profit DESC;
