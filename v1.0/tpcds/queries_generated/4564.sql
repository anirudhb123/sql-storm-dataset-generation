
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(COALESCE(ws.ws_net_profit, 0)) AS max_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.max_profit,
        DENSE_RANK() OVER (ORDER BY cs.max_profit DESC) AS customer_rank
    FROM 
        CustomerStats cs
)
SELECT 
    r.web_site_id,
    r.total_orders,
    r.total_sales,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.max_profit
FROM 
    RankedSales r
LEFT JOIN 
    TopCustomers tc ON r.total_orders > (SELECT AVG(total_orders) FROM RankedSales WHERE total_orders IS NOT NULL)
WHERE 
    r.sales_rank <= 5 AND 
    (tc.cd_gender = 'M' OR tc.cd_marital_status = 'M') 
ORDER BY 
    r.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
