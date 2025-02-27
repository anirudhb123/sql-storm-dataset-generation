
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY
        ws_item_sk
    
    UNION ALL
    
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY
        cs_item_sk
),
RankedSales AS (
    SELECT
        item.i_item_sk,
        item.i_item_id,
        COALESCE(SUM(ct.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(ct.total_sales), 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ct.total_sales), 0) DESC) AS sales_rank
    FROM
        item item
    LEFT JOIN (
        SELECT * FROM SalesCTE
    ) ct ON item.i_item_sk = ct.ws_item_sk OR item.i_item_sk = ct.cs_item_sk
    GROUP BY
        item.i_item_sk, item.i_item_id
),
HighVolumeItems AS (
    SELECT
        rs.i_item_sk,
        rs.i_item_id,
        rs.total_quantity,
        rs.total_sales
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_value
    FROM
        store_returns
    WHERE
        sr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY
        sr_item_sk
)
SELECT
    hvi.i_item_id,
    hvi.total_quantity,
    hvi.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS total_return_value,
    (hvi.total_sales - COALESCE(cr.total_return_value, 0)) AS net_sales,
    CASE 
        WHEN hvi.total_quantity = 0 THEN NULL
        ELSE (COALESCE(cr.total_returns, 0) * 100.0 / hvi.total_quantity) 
    END AS return_rate
FROM
    HighVolumeItems hvi
LEFT JOIN
    CustomerReturns cr ON hvi.i_item_sk = cr.sr_item_sk
ORDER BY
    net_sales DESC;
