
WITH sales_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_id,
        sum(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458849 AND 2458899 -- example date range (TBD)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, s.s_store_id, cd.cd_gender, hd.hd_income_band_sk
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    store_id,
    c_first_name,
    c_last_name,
    total_sales,
    cd_gender,
    purchase_count
FROM 
    ranked_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    hd_income_band_sk, total_sales DESC;
