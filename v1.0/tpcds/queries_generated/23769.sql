
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS estimated_purchase,
        MAX(CASE WHEN cm.cc_class = 'High' THEN 1 ELSE 0 END) AS high_value_customer
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        call_center cm ON c.c_current_hdemo_sk = cm.cc_call_center_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year, cd.cd_gender, cd.cd_marital_status
),
return_data AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(CASE WHEN wr.wr_return_qty IS NULL THEN 1 ELSE 0 END) AS null_quantity_count
    FROM 
        web_returns wr 
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_sales,
    cd.cd_gender, 
    cd.cd_marital_status,
    cd.high_value_customer,
    rd.total_returned,
    rd.total_return_amt,
    CASE 
        WHEN sd.total_sales > 100000 THEN 'Very High' 
        WHEN sd.total_sales BETWEEN 50000 AND 100000 THEN 'High'
        WHEN sd.total_sales BETWEEN 10000 AND 50000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_sales DESC) AS gender_rank
FROM 
    sales_data sd
LEFT JOIN 
    customer_data cd ON cd.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT cdemo.cd_demo_sk FROM customer_demographics cdemo))
LEFT JOIN 
    return_data rd ON sd.ws_item_sk = rd.wr_item_sk
WHERE 
    rd.total_returned IS NOT NULL
ORDER BY 
    cd.cd_gender, sd.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
