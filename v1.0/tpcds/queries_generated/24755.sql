
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        COALESCE(ws.ws_sales_price, 0) AS sales_price,
        ws.ws_quantity,
        COALESCE(cr.cr_return_quantity, 0) AS return_quantity,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns cr ON ws.ws_item_sk = cr.wr_item_sk AND ws.ws_order_number = cr.wr_order_number
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.sales_price,
        sd.ws_quantity,
        SUM(sd.return_quantity) OVER (PARTITION BY sd.ws_item_sk) AS total_returns,
        CASE 
            WHEN COUNT(DISTINCT sd.ws_item_sk) = 1 THEN 'Single Item'
            ELSE 'Multiple Items'
        END AS item_count_flag
    FROM 
        SalesData sd
    WHERE 
        sd.sales_price > 100 AND (sd.ws_quantity - sd.return_quantity) > 0
),
FinalReport AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        fs.ws_item_sk,
        fs.sales_price,
        fs.ws_quantity,
        fs.total_returns,
        fs.item_count_flag,
        DENSE_RANK() OVER (ORDER BY fs.total_returns DESC) AS return_rank
    FROM 
        RankedCustomers rc
    JOIN 
        FilteredSales fs ON rc.rn <= 5
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.ws_item_sk,
    fr.sales_price,
    fr.ws_quantity,
    fr.total_returns,
    fr.item_count_flag,
    CASE 
        WHEN fr.return_rank = 1 THEN 'Top Returner'
        ELSE 'Regular Returner'
    END AS customer_return_status
FROM 
    FinalReport fr
WHERE 
    fr.total_returns IS NOT NULL OR fr.sales_price IS NULL
ORDER BY 
    fr.c_customer_id, fr.return_rank;
