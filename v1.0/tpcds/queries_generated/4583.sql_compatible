
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), 
ReturnData AS (
    SELECT 
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns,
        cr.cr_item_sk
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    cd.total_orders,
    cd.avg_purchase_estimate,
    rd.total_returns,
    CASE 
        WHEN sd.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    SalesData sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerData cd ON cd.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = sd.ws_item_sk)
LEFT JOIN 
    ReturnData rd ON rd.cr_item_sk = sd.ws_item_sk
WHERE 
    sd.total_sales > 1000 AND 
    cd.total_orders IS NOT NULL
ORDER BY 
    sd.total_sales DESC, 
    rd.total_returns ASC
LIMIT 100;
