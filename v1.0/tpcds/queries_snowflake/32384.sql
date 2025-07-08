
WITH RECURSIVE sales_trend (d_year, total_profit) AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year

    UNION ALL

    SELECT 
        st.d_year - 1,
        (SELECT SUM(ws.ws_net_profit) 
         FROM web_sales ws 
         JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
         WHERE d.d_year = st.d_year - 1) AS total_profit
    FROM 
        sales_trend st
),
top_sales AS (
    SELECT 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
customer_data AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
)
SELECT 
    st.d_year, 
    st.total_profit,
    ts.i_item_id, 
    ts.total_quantity, 
    cd.c_customer_id, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_purchase_estimate, 
    cd.purchase_count
FROM 
    sales_trend st
JOIN 
    top_sales ts ON st.total_profit > 5000
JOIN 
    customer_data cd ON cd.purchase_count > 3
ORDER BY 
    st.d_year DESC, ts.total_profit DESC, cd.purchase_count DESC;
