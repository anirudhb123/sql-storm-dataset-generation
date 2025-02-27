
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        SUM(ws.ws_quantity + COALESCE(cs.cs_quantity, 0)) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        MIN(ws.ws_sales_price) AS min_sales_price,
        MAX(COALESCE(cs.cs_sales_price, 0)) AS max_catalog_sales_price
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    WHERE 
        (ws.ws_ship_date_sk IS NOT NULL OR cs.cs_ship_date_sk IS NULL)
          AND (ws.ws_quantity * 1.5) BETWEEN 10 AND 1000
          AND COALESCE(ws.ws_ext_sales_price, 0) > (COALESCE(cs.cs_ext_sales_price, 0) * 0.5)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price, cs.cs_quantity, cs.cs_sales_price
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 1 AND 365
    GROUP BY 
        wr.wr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        sd.min_sales_price,
        sd.max_catalog_sales_price
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        sd.total_quantity - COALESCE(rd.total_return_quantity, 0) > 15
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(CASE 
            WHEN b.total_quantity IS NULL THEN -1 
            ELSE b.total_quantity 
        END) AS avg_quantity_sold
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    (
        SELECT 
            ws_item_sk,
            SUM(total_quantity) AS total_quantity
        FROM 
            CombinedData
        GROUP BY 
            ws_item_sk
    ) b ON c.c_customer_sk = b.ws_item_sk
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT b.total_quantity) > 1
ORDER BY 
    total_purchase_estimate DESC NULLS LAST;
