
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(COALESCE(ss.total_net_profit, 0)) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    HAVING 
        COUNT(ws_order_number) > 0 AND total_profit > 0
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        total_quantity > 100
),
TopCustomers AS (
    SELECT 
        full_name,
        total_profit,
        order_count,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS customer_rank
    FROM 
        CustomerDetails
)
SELECT 
    tc.full_name,
    tc.total_profit,
    tc.order_count,
    pi.ws_item_sk,
    pi.total_quantity,
    pi.total_net_profit,
    tc.cd_gender,
    tc.cd_marital_status
FROM 
    TopCustomers tc
JOIN 
    PopularItems pi ON pi.total_net_profit > (SELECT AVG(total_net_profit) FROM PopularItems)
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_profit DESC, pi.total_quantity DESC;
