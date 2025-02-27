
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT web_site_sk
    FROM SalesCTE
    WHERE rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS row_num
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        ship_mode AS sm
    JOIN 
        web_sales AS ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
),
Returns AS (
    SELECT 
        cr_return_quantity,
        SUM(cr_return_amount) AS total_refunds
    FROM 
        catalog_returns
    GROUP BY 
        cr_return_quantity
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sm.sm_ship_mode_id,
    ws.total_sales,
    r.total_refunds
FROM 
    CustomerDetails AS cd
LEFT JOIN 
    TopWebsites AS tw ON cd.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales AS ws WHERE ws.ws_web_site_sk = tw.web_site_sk)
LEFT JOIN 
    ShippingModes AS sm ON sm.order_count > 5
LEFT JOIN 
    Returns AS r ON r.cr_return_quantity > 0
WHERE 
    cd.row_num <= 3
ORDER BY 
    cd.cd_gender, cd.cd_purchase_estimate DESC NULLS LAST;
