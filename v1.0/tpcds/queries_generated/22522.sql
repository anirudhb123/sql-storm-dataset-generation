
WITH CustomerData AS (
    SELECT 
        c.customer_id,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        COALESCE(cd.purchase_estimate, 0) AS purchase_estimate,
        CASE 
            WHEN cd.credit_rating IS NULL THEN 'UNKNOWN'
            ELSE cd.credit_rating 
        END AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY cd.purchase_estimate DESC) AS Rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

InventoryData AS (
    SELECT 
        i.i_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand < 0 THEN 0 ELSE inv.inv_quantity_on_hand END) AS total_quantity
    FROM 
        item i 
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
),

SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    c.customer_id,
    cd.gender,
    cd.marital_status,
    CASE 
        WHEN ISNULL(i.total_quantity, 0) > 0 THEN 'In Stock'
        ELSE 'Out of Stock'
    END AS stock_status,
    COALESCE(sd.total_sold, 0) AS total_sold,
    COALESCE(sd.total_profit, 0) AS total_profit,
    CASE 
        WHEN cd.gender = 'F' THEN 'Female'
        ELSE 'Male or Unknown'
    END AS gender_description
FROM 
    CustomerData cd
LEFT JOIN 
    InventoryData i ON cd.customer_id = CAST(i.i_item_sk AS CHAR(16)) -- Bizarre logic to join on incompatible keys
LEFT JOIN 
    SalesData sd ON sd.ws_item_sk = CAST(cd.purchase_estimate AS INTEGER) -- Obscure cast for joining
WHERE 
    cd.Rnk = 1 AND
    (cd.gender IS NOT NULL OR cd.marital_status IS NOT NULL) 
ORDER BY 
    5 DESC, 1 
LIMIT 100
OFFSET (SELECT COUNT(*) FROM CustomerData) - 100; -- Speculative logic using NULL handling and OFFSET
