WITH RECURSIVE supplier_totals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
monthly_order_totals AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS order_month,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31'
    GROUP BY 
        order_month
),
nation_average_balance AS (
    SELECT 
        n.n_nationkey,
        AVG(c.c_acctbal) AS avg_balance
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name,
    st.s_name,
    st.total_value,
    mot.order_month,
    mot.total_sales,
    nab.avg_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier_totals st ON st.s_suppkey = (SELECT s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey ORDER BY total_value DESC LIMIT 1)
LEFT JOIN 
    monthly_order_totals mot ON mot.order_month = DATE_TRUNC('month', CURRENT_DATE)
LEFT JOIN 
    nation_average_balance nab ON nab.n_nationkey = n.n_nationkey
WHERE 
    st.total_value IS NOT NULL
    AND (st.total_value > (SELECT AVG(total_value) FROM supplier_totals) OR nab.avg_balance IS NULL)
ORDER BY 
    r.r_name, st.total_value DESC;
