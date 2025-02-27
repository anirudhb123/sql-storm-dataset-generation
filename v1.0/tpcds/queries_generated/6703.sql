
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        COUNT(*) OVER (PARTITION BY ws.ws_sold_date_sk) AS sales_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.i_current_price,
        sales.rank_profit,
        sales.sales_count
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank_profit <= 10
)
SELECT 
    ts.i_product_name,
    ts.i_current_price,
    ts.rank_profit,
    ts.sales_count,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopSales ts
JOIN 
    customer c ON c.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = ts.ws_item_sk LIMIT 1)
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA' AND 
    cd.cd_marital_status = 'M'
ORDER BY 
    ts.sales_count DESC, 
    ts.rank_profit ASC;
