
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders,
        avg_sales_price,
        max_sales_price,
        min_sales_price,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        SalesData
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        total_spent,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerStats c
)
SELECT 
    TW.web_site_id,
    TW.total_net_profit,
    TW.total_orders,
    TC.c_customer_id,
    TC.c_first_name,
    TC.c_last_name,
    TC.total_spent
FROM 
    TopWebsites TW
JOIN 
    TopCustomers TC ON TW.rank = TC.rank
WHERE 
    TW.rank <= 10 AND TC.rank <= 10
ORDER BY 
    TW.total_net_profit DESC, TC.total_spent DESC;
