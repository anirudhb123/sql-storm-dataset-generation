
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_age,
        ca.ca_state,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        COUNT(DISTINCT ss.ticket_number) AS total_store_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_age, ca.ca_state, hd.hd_buy_potential
),
sales_summary AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(sd.ws_sales_price * sd.ws_quantity) DESC) AS sales_rank
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_state,
    COALESCE(ss.total_sales, 0) AS total_sales_amount,
    ss.sales_rank,
    CASE 
        WHEN ss.sales_rank <= 10 THEN 'Top Seller'
        WHEN ss.sales_rank <= 50 THEN 'Bestseller'
        ELSE 'Regular Item'
    END AS sales_category
FROM 
    customer_details cd
LEFT JOIN 
    sales_summary ss ON cd.c_customer_sk = ss.ws_item_sk 
WHERE 
    cd.buy_potential != 'UNKNOWN'
ORDER BY 
    total_sales_amount DESC, 
    cd.c_last_name ASC;
