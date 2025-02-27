WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
AggregatedSupplierData AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    ot.total_value,
    ag.supplier_count,
    ag.total_acctbal
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    OrderTotals ot ON p.p_partkey = ot.o_orderkey
JOIN 
    AggregatedSupplierData ag ON ag.region = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = (SELECT TOP 1 s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)))
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 1 AND 20)
ORDER BY 
    total_value DESC NULLS LAST;
