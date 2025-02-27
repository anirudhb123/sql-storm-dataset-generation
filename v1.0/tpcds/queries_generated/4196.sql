
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.web_site_sk
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), TopSales AS (
    SELECT 
        ss.web_site_sk,
        ss.total_sales,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        SalesSummary ss 
    JOIN 
        web_site ws ON ss.web_site_sk = ws.web_site_sk
    LEFT JOIN 
        CustomerInfo c ON c.rn <= 3
    LEFT JOIN 
        income_band ib ON c.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
)
SELECT 
    t.ws_web_page_sk,
    COUNT(DISTINCT t.ws_order_number) AS order_count,
    SUM(t.ws_ext_sales_price) AS total_revenue,
    COALESCE(AVG(r.r_return_amt), 0) AS avg_return_amt,
    st.total_sales AS web_sales_total,
    st.c_first_name,
    st.c_last_name,
    st.cd_gender,
    st.cd_marital_status
FROM 
    web_sales t 
LEFT JOIN 
    store_returns r ON t.ws_order_number = r.sr_ticket_number 
LEFT JOIN 
    TopSales st ON t.ws_web_site_sk = st.web_site_sk
WHERE 
    t.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    t.ws_web_page_sk, 
    st.total_sales, 
    st.c_first_name, 
    st.c_last_name,
    st.cd_gender,
    st.cd_marital_status
HAVING 
    SUM(t.ws_ext_sales_price) > 1000
ORDER BY 
    total_revenue DESC;
