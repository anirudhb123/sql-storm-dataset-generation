
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
SalesDetails AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        MAX(ws_sold_date_sk) AS last_sales_date
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        ad.full_address,
        sd.total_quantity,
        sd.total_sales,
        dd.d_year
    FROM 
        item i
    JOIN 
        SalesDetails sd ON i.i_item_sk = sd.ws_item_sk
    JOIN 
        AddressDetails ad ON ad.ca_address_sk = (SELECT ca_address_sk FROM customer WHERE c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = sd.ws_item_sk LIMIT 1))
    JOIN 
        date_dim dd ON dd.d_date_sk = sd.last_sales_date
    WHERE 
        sd.total_sales > 1000
)
SELECT 
    hii.i_item_sk,
    hii.i_item_desc,
    hii.full_address,
    hii.total_quantity,
    hii.total_sales,
    hii.d_year
FROM 
    HighValueItems hii
ORDER BY 
    hii.total_sales DESC
LIMIT 10;
