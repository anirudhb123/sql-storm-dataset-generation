
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FormattedSales AS (
    SELECT 
        CONCAT('Item ', i.i_item_id, ' - ', i.i_product_name) AS item_description,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_date AS sale_date
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    fs.item_description,
    SUM(fs.ws_quantity) AS total_quantity,
    SUM(fs.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT fs.ws_order_number) AS total_orders,
    MAX(fs.sale_date) AS last_purchase_date
FROM 
    RankedCustomers rc
JOIN 
    FormattedSales fs ON rc.c_customer_sk = fs.ws_bill_customer_sk
WHERE 
    rc.rank_by_purchase = 1
GROUP BY 
    rc.full_name, rc.cd_gender, rc.cd_marital_status, rc.cd_education_status, fs.item_description
ORDER BY 
    total_net_profit DESC, rc.full_name ASC;
