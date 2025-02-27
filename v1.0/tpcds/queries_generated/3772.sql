
WITH RankedSales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM
        web_returns wr
    WHERE
        wr.wr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY
        wr.wr_item_sk
),
SalesSummary AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid) AS total_sales_value,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN
        CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
    GROUP BY
        i.i_item_id, i.i_item_desc
)
SELECT
    s.i_item_id,
    s.i_item_desc,
    s.total_sales,
    s.total_sales_value,
    s.total_returns,
    s.total_return_amount,
    r.cs_net_paid AS last_sales_amount
FROM
    SalesSummary s
LEFT JOIN
    RankedSales r ON s.i_item_id = r.cs_item_sk AND r.sales_rank = 1
WHERE
    s.total_sales_value > 1000
ORDER BY
    s.total_sales_value DESC;
