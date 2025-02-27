
WITH RECURSIVE income_distribution AS (
    SELECT 
        hd_demo_sk, 
        ib_income_band_sk, 
        hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY hd_demo_sk) AS rnk
    FROM 
        household_demographics
    JOIN 
        income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE 
        ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer AS c
    LEFT JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
return_summary AS (
    SELECT 
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk
),
final_summary AS (
    SELECT 
        ds.d_date AS sales_date,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returned, 0) AS total_returned,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returned, 0)) AS net_sales,
        (COALESCE(ss.total_profit, 0) / NULLIF(COALESCE(ss.total_sales, 0), 0)) AS profit_margin,
        COUNT(DISTINCT ci.c_customer_id) AS distinct_customers
    FROM 
        date_dim ds
    LEFT JOIN 
        sales_summary ss ON ds.d_date_sk = ss.ws_sold_date_sk
    LEFT JOIN 
        return_summary rs ON ds.d_date_sk = rs.wr_returned_date_sk
    LEFT JOIN 
        customer_info ci ON ds.d_date_sk = ci.c_customer_id -- Assuming some mapping exists
    WHERE 
        ds.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ds.d_date, ss.total_sales, rs.total_returned, ss.total_profit
    ORDER BY 
        sales_date DESC
)
SELECT 
    fs.sales_date,
    fs.total_sales,
    fs.total_returned,
    fs.net_sales,
    fs.profit_margin,
    fs.distinct_customers,
    (SELECT COUNT(*) FROM customer_info ci2 WHERE ci2.purchase_rank <= 10) AS top_customers_count,
    (SELECT STRING_AGG(c.c_first_name || ' ' || c.c_last_name, ', ') 
        FROM customer_info ci3 
        LEFT JOIN customer c ON ci3.c_customer_id = c.c_customer_id 
        WHERE ci3.purchase_rank <= 10) AS top_customers_names
FROM 
    final_summary fs
ORDER BY 
    fs.sales_date DESC;
