WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.nation_name 
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank <= 5
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    p.p_brand, 
    p.p_type, 
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ts.nation_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, ts.nation_name
ORDER BY 
    revenue DESC, total_quantity DESC
LIMIT 10;
