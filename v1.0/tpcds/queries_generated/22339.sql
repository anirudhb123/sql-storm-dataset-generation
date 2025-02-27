
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq IN (2, 3, 4)
        )
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_sales) AS total_sales_value
    FROM 
        SalesData sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
    HAVING 
        SUM(sd.total_sales) > (
            SELECT AVG(total_sales) 
            FROM (
                SELECT SUM(ws.ws_net_paid_inc_tax) AS total_sales
                FROM web_sales ws
                GROUP BY ws.ws_item_sk
            ) AS average_sales
        )
),
ReturnedItems AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_value
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        ti.total_quantity_sold,
        ti.total_sales_value,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_return_value, 0) AS total_return_value,
        (ti.total_sales_value - COALESCE(ri.total_return_value, 0)) AS net_sales,
        CASE 
            WHEN COALESCE(ri.total_returns, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        TopItems ti
    LEFT JOIN 
        ReturnedItems ri ON ti.i_item_id = (SELECT i_item_id FROM item WHERE i_item_sk = ri.cr_item_sk)
)
SELECT 
    *,
    CASE 
        WHEN net_sales > 1000 THEN 'High Performance'
        WHEN net_sales BETWEEN 500 AND 1000 THEN 'Moderate Performance'
        ELSE 'Low Performance'
    END AS performance_category,
    CONCAT(i_item_desc, ' (ID: ', i_item_id, ')') AS detailed_description
FROM 
    FinalReport
ORDER BY 
    net_sales DESC, total_quantity_sold DESC;
