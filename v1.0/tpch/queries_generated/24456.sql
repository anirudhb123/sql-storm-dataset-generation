WITH supplier_ranked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
customer_with_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
large_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    p.p_name,
    p.p_mfgr,
    s.s_name AS supplier,
    COALESCE(ROUND(AVG(l.l_quantity), 2), 0) AS avg_quantity,
    COALESCE(SUM(l.l_extendedprice), 0.00) AS total_revenue,
    c.c_name AS customer_name,
    CASE 
        WHEN c.order_count > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier_ranked sr ON ps.ps_suppkey = sr.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    customer c ON c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT o_orderkey FROM large_orders))
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND sr.rank <= 3
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'Y')
GROUP BY 
    p.p_name, p.p_mfgr, s.s_name, c.c_name, r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC, avg_quantity ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
