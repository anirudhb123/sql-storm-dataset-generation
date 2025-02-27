
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.item_id,
        sd.total_quantity,
        sd.total_profit,
        sd.total_orders,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.total_orders > 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    tsi.item_id,
    tsi.total_quantity,
    tsi.total_profit,
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.order_count
FROM 
    TopSellingItems tsi
JOIN 
    CustomerDetails cd ON cd.order_count > 5
WHERE 
    tsi.rank <= 10
ORDER BY 
    tsi.total_profit DESC, cd.order_count DESC;
