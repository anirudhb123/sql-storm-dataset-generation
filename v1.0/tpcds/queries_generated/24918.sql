
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2000000 AND 2000050
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.i_current_price,
        sales.total_quantity_sold,
        sales.total_net_profit
    FROM 
        RankedSales sales
    JOIN 
        item AS item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rn = 1
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_customer_sk 
    WHERE 
        COALESCE(cd.cd_marital_status, 'N') = 'S' AND 
        (cd.cd_purchase_estimate > 1000 OR cd.cd_gender = 'F')
),
SalesSummary AS (
    SELECT 
        customers.c_customer_id,
        COUNT(DISTINCT sales.ws_item_sk) AS unique_items_purchased,
        SUM(sales.total_net_profit) AS total_spent
    FROM 
        FilteredCustomers customers
    JOIN 
        TopSales sales ON sales.total_quantity_sold > 0
    GROUP BY 
        customers.c_customer_id
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(SUM(ss.unique_items_purchased), 0) AS total_unique_items_purchased,
    COALESCE(SUM(ss.total_spent), 0) AS total_spent
FROM 
    customer_address a
LEFT JOIN 
    SalesSummary ss ON a.ca_address_sk = ss.c_customer_id
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    SUM(ss.total_spent) > 5000 OR COUNT(ss.unique_items_purchased) IS NULL
ORDER BY 
    total_spent DESC, a.ca_city ASC;
