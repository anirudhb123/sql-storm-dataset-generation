
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_coupon_amt) AS total_coupons,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.total_sales,
        ss.order_count,
        ss.total_coupons,
        ss.avg_profit
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.customer_id = c.c_customer_sk
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    hvc.total_coupons,
    hvc.avg_profit,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.web_page_sk) AS unique_web_pages
FROM 
    HighValueCustomers hvc
JOIN 
    customer_address ca ON hvc.customer_id = ca.ca_address_sk
JOIN 
    web_sales ws ON hvc.customer_id = ws.ws_bill_customer_sk
GROUP BY 
    hvc.c_customer_id, hvc.c_first_name, hvc.c_last_name, 
    hvc.total_sales, hvc.order_count, hvc.total_coupons, hvc.avg_profit,
    ca.ca_city, ca.ca_state
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
