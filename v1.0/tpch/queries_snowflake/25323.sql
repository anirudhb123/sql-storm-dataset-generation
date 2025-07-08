
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
CustomerRankings AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM 
        customer c
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(s.s_acctbal) AS total_supplier_balance,
    AVG(rs.num_parts) AS avg_parts_per_supplier,
    LISTAGG(s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
WHERE 
    rs.rank_acctbal <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_balance DESC;
