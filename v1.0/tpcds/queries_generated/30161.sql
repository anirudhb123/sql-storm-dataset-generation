
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
), 
TopSales AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        SUM(scte.ws_quantity) AS total_sales_quantity, 
        SUM(scte.ws_net_profit) AS total_net_profit
    FROM 
        SalesCTE scte
    JOIN 
        item ON scte.ws_item_sk = item.i_item_sk
    WHERE 
        scte.rn <= 10
    GROUP BY 
        item.i_item_id, item.i_product_name
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name || ' ' || c.c_last_name AS full_name, 
        CD.cd_gender, 
        CD.cd_marital_status, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, CD.cd_gender, CD.cd_marital_status
), 
SalesPerCustomer AS (
    SELECT 
        ci.full_name,
        COALESCE(SUM(ts.total_sales_quantity), 0) AS total_sales_quantity, 
        COALESCE(SUM(ts.total_net_profit), 0) AS total_net_profit
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        TopSales ts ON ts.i_item_id IN (
            SELECT i_item_id FROM item
            WHERE i_item_sk IN (
                SELECT i_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk
            )
        )
    GROUP BY 
        ci.full_name
)
SELECT 
    spc.full_name, 
    spc.total_sales_quantity, 
    spc.total_net_profit,
    CASE
        WHEN spc.total_spent > 1000 THEN 'High Value'
        WHEN spc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesPerCustomer spc
JOIN 
    CustomerInfo ci ON spc.full_name = ci.full_name
WHERE 
    spc.total_sales_quantity > 5
ORDER BY 
    spc.total_net_profit DESC 
LIMIT 50;
