
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
HomeDecorItems AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price, 
        COALESCE(ROUND(SUM(iss.total_quantity) * i.i_current_price, 2), 0) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        (SELECT item_sk, SUM(ws_quantity) total_quantity FROM web_sales GROUP BY item_sk) iss ON i.i_item_sk = iss.item_sk
    WHERE 
        i.i_category = 'Home Decor'
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price
), 
HighValueCustomers AS (
    SELECT 
        DISTINCT c.customer_id
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rnk <= 10 
        AND EXISTS (
            SELECT 1 FROM SalesData sd WHERE sd.total_profit > 50000
        )
)
SELECT 
    hdi.i_item_sk, 
    hdi.i_item_desc, 
    hdi.total_revenue,
    COALESCE(
        (SELECT MIN(c.c_birth_year) FROM customer c WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM HighValueCustomers)), 
        'N/A'
    ) AS earliest_birth_year,
    COALESCE(
        (SELECT MAX(c.c_birth_year) FROM customer c WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM HighValueCustomers)), 
        'N/A'
    ) AS latest_birth_year
FROM 
    HomeDecorItems hdi
WHERE 
    hdi.total_revenue IS NOT NULL
ORDER BY 
    hdi.total_revenue DESC
FETCH FIRST 20 ROWS ONLY;
