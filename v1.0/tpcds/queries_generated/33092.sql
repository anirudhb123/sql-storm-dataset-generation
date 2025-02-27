
WITH RECURSIVE ItemCTE AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_current_price,
        i_size,
        i_formulation,
        1 AS level
    FROM item
    WHERE i_size IS NOT NULL

    UNION ALL

    SELECT 
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_current_price * 1.1 AS i_current_price,
        i_size,
        i_formulation,
        level + 1
    FROM ItemCTE
    WHERE level < 3
), SalesData AS (
    SELECT 
        ws.sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_date AS sales_date,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY d.d_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), ReturnsData AS (
    SELECT 
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amt,
        cr_item_sk,
        d.d_date AS return_date
    FROM catalog_returns
    JOIN date_dim d ON catalog_returns.cr_returned_date_sk = d.d_date_sk
),
SalesReturns AS (
    SELECT 
        sd.sold_date_sk,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.cumulative_sales,
        COALESCE(SUM(rd.cr_return_quantity), 0) AS total_returns
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.ws_item_sk = rd.cr_item_sk AND sd.sold_date_sk = rd.cr_returned_date_sk
    GROUP BY sd.sold_date_sk, sd.ws_item_sk, sd.ws_sales_price, sd.ws_quantity, sd.cumulative_sales
)
SELECT 
    itm.i_item_id,
    itm.i_item_desc,
    s.ws_quantity,
    s.cumulative_sales,
    s.total_returns,
    (s.cumulative_sales - s.total_returns) AS net_sales,
    CASE 
        WHEN (s.cumulative_sales - s.total_returns) > 1000 THEN 'High' 
        WHEN (s.cumulative_sales - s.total_returns) BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'Low' 
    END AS sales_category
FROM ItemCTE itm
JOIN SalesReturns s ON itm.i_item_sk = s.ws_item_sk
ORDER BY net_sales DESC, itm.i_item_id;
