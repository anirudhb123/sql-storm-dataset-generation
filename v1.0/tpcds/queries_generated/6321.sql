
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        r.rank,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.total_profit,
    ti.i_item_id,
    ti.total_quantity,
    ti.total_sales
FROM 
    CustomerStats cs
JOIN 
    TopItems ti ON cs.cd_gender = (SELECT DISTINCT cd_gender FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk)
ORDER BY 
    cs.total_profit DESC, 
    cs.customer_count DESC;
