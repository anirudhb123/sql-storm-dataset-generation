
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        sd.total_orders,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price
    FROM 
        SalesData sd
    INNER JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.profit_rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        DATEDIFF(CURDATE(), DATE(CONCAT(c.c_birth_year, '-', c.c_birth_month, '-', c.c_birth_day))) AS age,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        SUM(cs.ss_net_paid) AS total_spent,
        COUNT(cs.ss_ticket_number) AS purchase_count
    FROM 
        store_sales cs
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.age,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(ss.total_spent, 0) AS total_spent,
    COALESCE(ss.purchase_count, 0) AS purchase_count,
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_net_profit
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.c_customer_sk
RIGHT JOIN 
    TopSales ts ON ts.ws_item_sk = ss.c_customer_sk
WHERE 
    (cs.age > 25 AND cs.cd_gender = 'F') OR 
    (cs.age <= 25 AND cs.cd_marital_status = 'S')
ORDER BY 
    ts.total_net_profit DESC, cs.total_spent DESC;
