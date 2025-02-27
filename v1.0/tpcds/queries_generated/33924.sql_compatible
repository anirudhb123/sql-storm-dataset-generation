
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, ws_bill_customer_sk, ws_ship_customer_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(COALESCE(s.total_profit, 0)) AS customer_total_profit,
        COUNT(DISTINCT s.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
),
TopCustomers AS (
    SELECT 
        cs.*, 
        RANK() OVER (ORDER BY customer_total_profit DESC) AS profit_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_income_band_sk,
    tc.customer_total_profit,
    tc.total_orders,
    CASE 
        WHEN tc.customer_total_profit > (SELECT AVG(customer_total_profit) FROM CustomerSummary) THEN 'Above Average'
        ELSE 'Below Average' 
    END AS profit_comparison
FROM 
    TopCustomers tc
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.customer_total_profit DESC;
