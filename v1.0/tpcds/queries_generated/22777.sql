
WITH RecursiveSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_paid) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        MAX(cs_sold_date_sk) AS last_sale_date
    FROM 
        catalog_sales
    WHERE 
        cs_net_paid > 0 -- Only consider positive sales
    GROUP BY 
        cs_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        cs.total_sales,
        cs.total_orders,
        cs.last_sale_date,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        item i
    LEFT JOIN 
        RecursiveSales cs ON i.i_item_sk = cs.cs_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
),
HighSales AS (
    SELECT 
        item_desc, 
        total_sales,
        total_orders,
        last_sale_date,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_sales > 1000 THEN 'High Sales'
            ELSE 'Regular Sales'
        END AS sales_category
    FROM 
        ItemDetails 
    WHERE 
        sales_rank = 1
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
ShippingDetails AS (
    SELECT 
        ws.ws_item_sk,
        sm.sm_type,
        COUNT(ws.ws_order_number) AS total_shipments
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_item_sk, sm.sm_type
)
SELECT 
    hs.item_desc,
    hs.total_sales,
    hs.sales_category,
    cs.total_spent,
    cs.num_orders,
    sd.total_shipments,
    CASE
        WHEN cs.total_spent IS NULL THEN 'New Customer'
        WHEN cs.total_spent <= 100 THEN 'Low Spender'
        ELSE 'Regular Spender'
    END AS customer_status
FROM 
    HighSales hs
LEFT JOIN 
    CustomerSales cs ON hs.item_desc = cs.c_customer_id  -- Using item_desc for joining to showcase corner case
LEFT JOIN 
    ShippingDetails sd ON hs.total_orders = sd.total_shipments -- Example of NULL logic involving aggregates
WHERE 
    (hs.total_sales IS NOT NULL OR cs.total_spent IS NOT NULL) -- Ensuring that at least one of the parameters is not NULL
ORDER BY 
    hs.total_sales DESC, 
    cs.total_spent ASC;
