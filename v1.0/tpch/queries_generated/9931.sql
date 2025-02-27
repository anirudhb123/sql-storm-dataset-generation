WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
), HighCostSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.total_supplycost) AS total_high_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_nationkey = s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.supplier_count,
    r.total_high_cost,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM 
    HighCostSuppliers r
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
GROUP BY 
    r.r_name, r.supplier_count, r.total_high_cost
ORDER BY 
    total_high_cost DESC;
