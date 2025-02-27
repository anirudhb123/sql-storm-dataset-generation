
WITH SalesData AS (
    SELECT
        w.w_warehouse_id,
        s.s_store_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2458857 AND 2458865 -- Example date range
    GROUP BY
        w.w_warehouse_id, s.s_store_id
),
ReturnsData AS (
    SELECT
        w.w_warehouse_id,
        s.s_store_id,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM
        web_returns wr
    JOIN
        warehouse w ON wr.wr_returned_addr_sk = w.w_warehouse_sk
    JOIN
        store s ON wr.wr_returning_addr_sk = s.s_store_sk
    WHERE
        wr.wr_returned_date_sk BETWEEN 2458857 AND 2458865 -- Example date range
    GROUP BY
        w.w_warehouse_id, s.s_store_id
)
SELECT
    sd.w_warehouse_id,
    sd.s_store_id,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount,
    sd.total_profit,
    COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    COALESCE(rd.total_return_loss, 0) AS total_return_loss,
    (sd.total_sales - COALESCE(rd.total_return_amount, 0)) AS net_sales,
    (sd.total_profit - COALESCE(rd.total_return_loss, 0)) AS net_profit
FROM
    SalesData sd
LEFT JOIN
    ReturnsData rd ON sd.w_warehouse_id = rd.w_warehouse_id AND sd.s_store_id = rd.s_store_id
ORDER BY
    net_sales DESC,
    net_profit DESC;
