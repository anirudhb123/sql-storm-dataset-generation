
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ib.ib_upper_bound
    FROM 
        CustomerInfo ci
    JOIN 
        household_demographics hd ON ci.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_upper_bound >= 100000
),
TopItems AS (
    SELECT 
        is.ws_item_sk,
        it.i_item_desc,
        it.i_current_price,
        is.total_quantity,
        is.total_sales
    FROM 
        ItemSales is
    JOIN 
        item it ON is.ws_item_sk = it.i_item_sk 
    WHERE 
        is.total_sales >= (SELECT AVG(total_sales) FROM ItemSales)
)
SELECT 
    hvc.full_name,
    hvc.ca_city,
    hvc.ca_state,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales
FROM 
    HighValueCustomers hvc
JOIN 
    TopItems ti ON hvc.c_customer_sk = ti.ws_item_sk
ORDER BY 
    ti.total_sales DESC, 
    hvc.full_name;
