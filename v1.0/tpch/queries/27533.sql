WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderedSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_parts,
        rs.total_supply_cost,
        RANK() OVER (ORDER BY rs.total_supply_cost DESC, rs.total_parts DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
)
SELECT 
    os.s_name,
    n.n_name AS nation_name,
    COUNT(c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_sales,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    OrderedSuppliers os
JOIN 
    supplier s ON os.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    os.supplier_rank <= 10
GROUP BY 
    os.s_name, n.n_name
ORDER BY 
    total_sales DESC;
