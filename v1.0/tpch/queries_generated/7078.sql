WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
QualifiedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipmode = 'TRUCK'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    r.r_name,
    rs.s_name,
    COUNT(DISTINCT q.o_orderkey) AS total_orders,
    SUM(q.total_revenue) AS total_revenue,
    AVG(rs.total_cost) AS avg_supplier_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.n_nationkey = n.n_nationkey
JOIN 
    QualifiedOrders q ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = q.o_orderkey LIMIT 1))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, rs.s_name
HAVING 
    COUNT(DISTINCT q.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
