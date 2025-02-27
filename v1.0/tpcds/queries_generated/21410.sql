
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year >= 2021
    GROUP BY ws.ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_dep_count + cd.cd_dep_count, 0) AS total_dependencies,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_spent,
        CASE 
            WHEN COALESCE(SUM(ws.ws_sales_price), 0) > 1000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_type
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_dep_count
),
high_selling_items AS (
    SELECT 
        ris.ws_item_sk, 
        SUM(ris.total_sold) AS total_sales
    FROM ranked_sales ris
    WHERE ris.sales_rank <= 5
    GROUP BY ris.ws_item_sk
),
return_summary AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
final_report AS (
    SELECT 
        cs.full_name,
        cs.cd_gender,
        cs.customer_type,
        hi.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        CASE 
            WHEN hi.total_sales - COALESCE(rs.total_return_value, 0) > 0 THEN 'Profitable'
            ELSE 'Unprofitable'
        END AS profitability
    FROM customer_summary cs
    JOIN high_selling_items hi ON cs.c_customer_sk = hi.ws_item_sk
    LEFT JOIN return_summary rs ON hi.ws_item_sk = rs.wr_item_sk
)
SELECT 
    *,
    CASE
        WHEN total_sales > (SELECT AVG(total_sales) FROM high_selling_items) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category
FROM final_report
WHERE cd_gender = 'F'
ORDER BY total_sales DESC, full_name ASC;
