
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND
        i.i_rec_start_date <= CURRENT_DATE AND
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns AS wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT d.d_date_sk FROM date_dim AS d WHERE d.d_date = CURRENT_DATE - INTERVAL '30' DAY)
    GROUP BY 
        wr.wr_item_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        AVG(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_purchase_estimate ELSE NULL END) AS avg_female_purchase_estimate,
        MAX(cd.cd_credit_rating) AS max_credit_rating
    FROM 
        customer AS c
    LEFT JOIN 
        web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit,
    COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    cs.c_customer_sk,
    cs.return_count,
    cs.avg_female_purchase_estimate,
    cs.max_credit_rating
FROM 
    SalesData AS sd
LEFT JOIN 
    ReturnData AS rd ON sd.ws_item_sk = rd.wr_item_sk
JOIN 
    CustomerStatistics AS cs ON cs.c_customer_sk IN (SELECT c.c_customer_sk FROM customer AS c WHERE c.c_current_addr_sk IS NOT NULL)
WHERE 
    sd.sales_rank <= 10
ORDER BY 
    sd.total_sales DESC;
