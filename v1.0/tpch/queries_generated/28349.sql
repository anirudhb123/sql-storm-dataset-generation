WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, p.p_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT rs.s_suppkey) AS num_suppliers,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    ts.region_name,
    ts.num_suppliers,
    ts.total_acctbal,
    ROUND(AVG(ps.ps_supplycost), 2) AS avg_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.num_suppliers = (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s WHERE s.s_suppkey IN (SELECT s.s_suppkey FROM RankedSuppliers rs WHERE rs.rank <= 3))
GROUP BY 
    ts.region_name, ts.num_suppliers, ts.total_acctbal
ORDER BY 
    ts.total_acctbal DESC;
