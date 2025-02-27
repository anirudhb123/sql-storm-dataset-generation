
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_bill_customer_sk) OVER (PARTITION BY ws.ws_item_sk) AS unique_customers
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
FilteredSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_sales_price,
        sd.price_rank,
        sd.total_quantity_sold,
        sd.unique_customers
    FROM 
        SalesData AS sd
    WHERE 
        sd.price_rank <= 5
        AND sd.total_quantity_sold > 100
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        COALESCE(hd.hd_dep_count, 0) AS dep_count,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
    FROM 
        customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    WHERE 
        cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, hd.hd_vehicle_count, hd.hd_dep_count
)
SELECT 
    f.ws_order_number,
    f.ws_item_sk,
    f.ws_quantity,
    f.ws_sales_price,
    c.c_customer_id,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    c.vehicle_count,
    c.dep_count,
    c.total_web_returns
FROM 
    FilteredSales AS f
JOIN 
    CustomerData AS c ON f.ws_item_sk = (SELECT i.i_item_sk FROM item AS i WHERE i.i_item_sk = f.ws_item_sk AND i.i_current_price = f.ws_sales_price)
ORDER BY 
    f.ws_order_number, f.ws_item_sk;
