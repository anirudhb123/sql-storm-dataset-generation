
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    tp.ws_item_sk,
    tp.total_quantity,
    tp.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopProducts tp
JOIN 
    SalesData sd ON tp.ws_item_sk = sd.ws_item_sk
JOIN 
    CustomerData cd ON cd.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = tp.ws_item_sk)
WHERE 
    tp.profit_rank <= 10
ORDER BY 
    tp.total_net_profit DESC;
