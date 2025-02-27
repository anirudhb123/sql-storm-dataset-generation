
WITH RECURSIVE SalesTrend AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
    UNION ALL
    SELECT 
        DATEADD(day, 1, sale_date),
        SUM(ws.ws_sales_price)
    FROM 
        SalesTrend st
    LEFT JOIN 
        web_sales ws ON DATEADD(day, 1, st.sale_date) = d.d_date
    WHERE 
        st.sale_date < '2023-12-31'
    GROUP BY 
        DATEADD(day, 1, st.sale_date)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
ReturnStats AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.total_net_paid, 0) AS total_net_paid,
    COALESCE(rs.total_return_amt, 0) AS total_return_amount,
    st.sale_date,
    st.total_sales
FROM 
    CustomerStats cs
LEFT JOIN 
    ReturnStats rs ON cs.c_customer_id = rs.refunded_customer_sk
LEFT JOIN 
    SalesTrend st ON st.sale_date BETWEEN '2023-01-01' AND '2023-12-31'
WHERE 
    (cs.order_count > 0 OR rs.total_return_amt IS NOT NULL)
ORDER BY 
    st.sale_date DESC, cs.total_net_paid DESC;
