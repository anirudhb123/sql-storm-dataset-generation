
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 90 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        rs.total_returns,
        rs.total_return_amount,
        rs.return_count
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        ReturnStats rs ON i.i_item_sk = rs.sr_item_sk
    GROUP BY 
        i.i_item_id, 
        i.i_item_desc, 
        rs.total_returns, 
        rs.total_return_amount, 
        rs.return_count
    ORDER BY 
        total_sales DESC
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_sold,
    tsi.total_sales,
    COALESCE(tsi.total_returns, 0) AS total_returns,
    COALESCE(tsi.total_return_amount, 0) AS total_return_amount,
    tsi.return_count
FROM 
    TopSellingItems tsi
WHERE 
    tsi.total_sold > (SELECT AVG(total_sold) FROM TopSellingItems)
UNION ALL
SELECT 
    'Average' AS i_item_id,
    'Average of Sales' AS i_item_desc,
    AVG(total_sold),
    AVG(total_sales),
    AVG(total_returns),
    AVG(total_return_amount),
    AVG(return_count)
FROM 
    TopSellingItems
ORDER BY 
    total_sales DESC;
