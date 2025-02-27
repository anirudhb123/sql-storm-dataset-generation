
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM 
        CustomerStats c
    WHERE 
        rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
SalesWithPromotions AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        s.total_profit,
        CASE 
            WHEN p.p_promo_sk IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS promo_used
    FROM 
        SalesData s
    LEFT JOIN 
        promotion p ON s.ws_item_sk = p.p_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    swp.total_quantity,
    swp.total_sales,
    swp.total_profit,
    swp.promo_used
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesWithPromotions swp ON tc.c_customer_sk = swp.ws_item_sk
WHERE 
    swp.total_profit IS NOT NULL
ORDER BY 
    tc.c_last_name ASC, 
    tc.c_first_name ASC;
