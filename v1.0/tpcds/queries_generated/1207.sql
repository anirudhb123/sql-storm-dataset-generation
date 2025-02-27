
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk AS sold_date,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        sold_date,
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        sales_data
    WHERE 
        sales_rank <= 10
),
customer_profiles AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
daily_summary AS (
    SELECT 
        d.d_date AS transaction_date,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ts.total_sales) AS total_sales,
        SUM(ts.total_quantity) AS total_quantity
    FROM 
        date_dim d
    LEFT JOIN 
        top_items ts ON d.d_date_sk = ts.sold_date
    LEFT JOIN 
        customer_profiles c ON ts.ws_item_sk IN (
            SELECT 
                ws.ws_item_sk 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_sold_date_sk = ts.sold_date
        )
    GROUP BY 
        d.d_date
)
SELECT 
    ds.transaction_date,
    ds.num_customers,
    ds.total_sales,
    ds.total_quantity,
    CASE 
        WHEN ds.total_sales > 1000000 THEN 'High Sales'
        WHEN ds.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    daily_summary ds
WHERE 
    ds.transaction_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    ds.transaction_date;
