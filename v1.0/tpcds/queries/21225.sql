
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_value,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_density_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451560 
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales_value,
        rs.total_quantity_sold,
        i.i_product_name,
        COALESCE(NULLIF(i.i_color, ''), 'No color specified') AS color_info
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank = 1
),
CustomerReturns AS (
    SELECT 
        CASE 
            WHEN cr.cr_return_quantity > 0 THEN 'Returns'
            ELSE 'No Returns'
        END AS return_status,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IS NOT NULL
    GROUP BY 
        return_status
),
FinalReport AS (
    SELECT 
        ti.i_product_name,
        ti.total_sales_value,
        ti.total_quantity_sold,
        cr.return_status,
        cr.total_returned
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerReturns cr ON cr.total_returned > 10
)
SELECT 
    FR.i_product_name,
    FR.total_sales_value,
    FR.total_quantity_sold,
    COALESCE(FR.return_status, 'No Return Information') AS return_info,
    COALESCE(FR.total_returned, 0) AS total_returns
FROM 
    FinalReport FR
WHERE 
    FR.total_sales_value > 1000
ORDER BY 
    FR.total_sales_value DESC;
