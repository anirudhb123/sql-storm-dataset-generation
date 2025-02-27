WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
MaxRankedSuppliers AS (
    SELECT 
        rs.s_nationkey,
        COUNT(*) AS supplier_count
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.s_nationkey
)
SELECT 
    r.r_name,
    mr.supplier_count,
    SUM(o.o_totalprice) AS total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
JOIN 
    MaxRankedSuppliers mr ON n.n_nationkey = mr.s_nationkey
JOIN 
    orders o ON o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
GROUP BY 
    r.r_name, mr.supplier_count
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, r.r_name ASC;
