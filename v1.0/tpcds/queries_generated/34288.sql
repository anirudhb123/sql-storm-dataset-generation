
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT 
        i_item_id, 
        i_product_name, 
        si.total_quantity,
        si.total_profit
    FROM 
        SalesCTE si
    JOIN 
        item ON si.ws_item_sk = item.i_item_sk
    WHERE 
        si.rank <= 10
), 
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS customer_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
), 
SalesByGender AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender
) 
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_profit,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.customer_profit,
    sg.total_profit AS gender_profit
FROM 
    TopItems ti
LEFT JOIN 
    CustomerStats cs ON cs.total_orders > 0
LEFT JOIN 
    SalesByGender sg ON cs.cd_gender = sg.cd_gender
ORDER BY 
    ti.total_profit DESC, cs.customer_profit DESC;
