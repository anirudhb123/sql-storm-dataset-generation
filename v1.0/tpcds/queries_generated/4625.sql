
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_payment,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
),
Demos AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_profit
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cs.c_customer_id = (
            SELECT c.c_customer_id 
            FROM customer c 
            WHERE c.c_current_cdemo_sk = cd.cd_demo_sk
        )
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    COUNT(d.cd_demo_sk) AS num_customers,
    AVG(d.total_profit) AS avg_profit,
    NULLIF(SUM(d.total_profit), 0) AS total_profit,
    CASE 
        WHEN AVG(d.total_profit) > 1000 THEN 'High Spending'
        ELSE 'Low Spending'
    END AS spending_category
FROM 
    Demos d
GROUP BY 
    d.cd_gender, d.cd_marital_status
HAVING 
    AVG(d.total_profit) > 500
ORDER BY 
    num_customers DESC
LIMIT 10;
