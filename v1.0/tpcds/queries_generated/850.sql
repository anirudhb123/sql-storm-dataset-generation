
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        COALESCE(NULLIF(MAX(ws.ws_net_paid_inc_tax), 0), AVG(ws.ws_net_paid)) AS avg_net_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
return_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
performance_benchmark AS (
    SELECT 
        s.item_desc,
        sd.total_quantity,
        sd.total_net_profit,
        sd.total_sales_price,
        rd.total_return_quantity,
        rd.total_return_amt,
        sd.avg_net_paid,
        (sd.total_sales_price - COALESCE(rd.total_return_amt, 0)) AS net_sales,
        (sd.total_net_profit - COALESCE(rd.total_return_amt, 0)) AS adjusted_profit
    FROM 
        item s
    LEFT JOIN 
        sales_data sd ON s.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        return_data rd ON s.i_item_sk = rd.wr_item_sk
    WHERE 
        sd.total_quantity > 100 
        AND (s.i_current_price * sd.total_quantity) > 1000
)
SELECT 
    pb.item_desc,
    pb.total_quantity,
    pb.total_net_profit,
    pb.net_sales,
    pb.adjusted_profit,
    RANK() OVER (ORDER BY pb.adjusted_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY (CASE WHEN pb.adjusted_profit > 500 THEN 'High Profit' ELSE 'Low Profit' END) ORDER BY pb.adjusted_profit DESC) AS profit_group_row_num
FROM 
    performance_benchmark pb
WHERE 
    pb.net_sales > 0
ORDER BY 
    pb.adjusted_profit DESC
LIMIT 50;
