
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(SalesCTE.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(SalesCTE.total_net_profit), 0) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(SalesCTE.total_net_profit), 0) DESC) AS item_rank
    FROM 
        item
    LEFT JOIN 
        SalesCTE ON item.i_item_sk = SalesCTE.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
CustomerInfo AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        customer.c_current_cdemo_sk,
        demographics.cd_gender,
        demographics.cd_dep_count,
        COUNT(DISTINCT sales.ws_order_number) AS order_count
    FROM 
        customer
    JOIN 
        customer_demographics demographics ON customer.c_current_cdemo_sk = demographics.cd_demo_sk
    LEFT JOIN 
        web_sales sales ON customer.c_customer_sk = sales.ws_bill_customer_sk
    GROUP BY 
        customer.c_customer_sk, customer.c_first_name, customer.c_last_name, demographics.cd_gender, demographics.cd_dep_count
),
FinalOutput AS (
    SELECT 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.cd_gender, 
        ci.order_count,
        tsi.i_item_id,
        tsi.i_item_desc,
        tsi.total_quantity_sold,
        tsi.total_net_profit
    FROM 
        CustomerInfo ci
    JOIN 
        TopSellingItems tsi ON ci.order_count > 0 AND tsi.total_quantity_sold > 0
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.order_count,
    f.i_item_id,
    f.i_item_desc,
    f.total_quantity_sold,
    f.total_net_profit
FROM 
    FinalOutput f
WHERE 
    f.cd_gender IS NOT NULL
ORDER BY 
    f.total_net_profit DESC, 
    f.order_count DESC
LIMIT 50 OFFSET 10;
