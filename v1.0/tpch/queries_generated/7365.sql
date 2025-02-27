WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT h.c_custkey) AS high_value_customers,
    SUM(h.total_spent) AS total_spent_by_high_value_customers,
    AVG(ranked.total_sales) AS avg_daily_sales
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    RankedOrders ranked ON ps.ps_partkey IN (
        SELECT DISTINCT l.l_partkey
        FROM lineitem l
        WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    )
JOIN 
    HighValueCustomers h ON s.s_nationkey = h.c_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    total_spent_by_high_value_customers DESC;
