
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS recent_sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(scte.ws_net_paid) AS total_sales,
        COUNT(scte.ws_order_number) AS sales_count
    FROM 
        SalesCTE scte
    JOIN 
        item ON scte.ws_item_sk = item.i_item_sk
    WHERE 
        scte.recent_sales_rank <= 5
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerReturns AS (
    SELECT 
        cr.refunded_customer_sk,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.refunded_customer_sk
),
ReturnImpact AS (
    SELECT 
        cs.i_item_id,
        cs.total_sales,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        (cs.total_sales - COALESCE(cr.total_returned_amount, 0)) AS net_sales
    FROM 
        TopSales cs
    LEFT JOIN 
        CustomerReturns cr ON cs.i_item_id = cr.refunded_customer_sk -- Assuming some relation
)
SELECT 
    r.i_item_id,
    r.total_sales,
    r.total_returned_amount,
    r.net_sales,
    CAST((100.0 * (r.net_sales / NULLIF(r.total_sales, 0))) AS DECIMAL(5,2)) AS percentage_net_sales
FROM 
    ReturnImpact r
WHERE 
    r.net_sales > 0
ORDER BY 
    r.net_sales DESC, r.total_sales DESC
LIMIT 10;
