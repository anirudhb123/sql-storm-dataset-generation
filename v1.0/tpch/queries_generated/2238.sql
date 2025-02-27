WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COALESCE(rs.total_cost, 0) AS supplier_cost,
    HVO.o_orderdate,
    HVO.c_mktsegment,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returns_count
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
JOIN 
    HighValueOrders HVO ON l.l_orderkey = HVO.o_orderkey
GROUP BY 
    p.p_name, HVO.o_orderdate, HVO.c_mktsegment, rs.total_cost
HAVING 
    revenue > 10000 
    AND supplier_cost IS NOT NULL
ORDER BY 
    revenue DESC
LIMIT 50;
