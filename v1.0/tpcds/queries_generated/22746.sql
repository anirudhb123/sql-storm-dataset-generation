
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_order_date,
        MIN(ws.ws_sold_date_sk) AS first_order_date
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count
),
PaymentCounts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(*) FILTER (WHERE wr_returned_date_sk IS NOT NULL) AS total_returns,
        SUM(IFNULL(wr_return_amt, 0)) AS total_return_amounts
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    COALESCE(p.total_returns, 0) AS total_returns,
    p.total_return_amounts,
    rs.total_sales,
    CASE 
        WHEN p.total_return_amounts > cs.total_spent THEN 'High-risk customer'
        WHEN cs.total_orders < 2 THEN 'New customer'
        ELSE 'Regular customer'
    END AS customer_type
FROM 
    CustomerStats cs
LEFT JOIN 
    PaymentCounts p ON cs.c_customer_sk = p.c_customer_sk
LEFT JOIN 
    RankedSales rs ON cs.total_spent = rs.total_sales
WHERE 
    cs.total_orders > 0
AND 
    (p.total_returns IS NULL OR p.total_returns < 5)
ORDER BY 
    cs.total_spent DESC, cs.c_last_name
LIMIT 50;
