
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk, 
        SUM(ws.ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ws.bill_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND ca.ca_state = 'CA'
    GROUP BY 
        ws.bill_customer_sk
), sales_summary AS (
    SELECT 
        bill_customer_sk, 
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    ss.total_sales,
    ss.order_count,
    COUNT(DISTINCT ws.ws_order_number) AS return_count,
    SUM(ws.net_paid) AS total_returns
FROM 
    sales_summary ss
JOIN 
    customer cs ON cs.c_customer_sk = ss.bill_customer_sk
LEFT JOIN 
    web_returns ws ON ws.returning_customer_sk = ss.bill_customer_sk
GROUP BY 
    cs.c_first_name, cs.c_last_name, ss.total_sales, ss.order_count
ORDER BY 
    ss.total_sales DESC;
