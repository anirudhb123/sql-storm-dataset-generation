
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        n.n_name AS region_name, 
        rs.s_name AS supplier_name, 
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_nationkey = (SELECT n_nationkey FROM nation ORDER BY n_nationkey LIMIT 1) 
    WHERE 
        rs.rank <= 5
)
SELECT 
    ts.region_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    TopSuppliers ts
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c JOIN nation n ON c.c_nationkey = n.n_nationkey WHERE n.n_name = ts.region_name)
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    ts.region_name
ORDER BY 
    total_revenue DESC;
