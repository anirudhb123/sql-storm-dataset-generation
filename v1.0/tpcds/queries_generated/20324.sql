
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_score,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Unavailable' 
            ELSE CONCAT('Price: $', CAST(i.i_current_price AS VARCHAR(20))) 
        END AS price_info
    FROM 
        item i
    WHERE 
        i.i_rec_start_date < (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_current_year = 'Y')
),
AggregatedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    it.i_item_desc,
    it.price_info,
    COALESCE(as.total_quantity, 0) AS total_quantity,
    COALESCE(as.total_sales_value, 0.00) AS total_sales_value,
    CASE 
        WHEN as.total_sales_value > 0 THEN 'Positive Sales'
        ELSE 'No Sales'
    END AS sales_status
FROM 
    RankedCustomers rc
LEFT JOIN 
    AggregatedSales as ON rc.c_customer_sk = as.ws_bill_customer_sk
JOIN 
    ItemDetails it ON as.ws_item_sk = it.i_item_sk
WHERE 
    (rc.gender_rank <= 10 OR rc.cd_marital_status = 'S')
ORDER BY 
    rc.cd_gender, sales_status DESC, total_sales_value DESC
FETCH FIRST 100 ROWS ONLY;
