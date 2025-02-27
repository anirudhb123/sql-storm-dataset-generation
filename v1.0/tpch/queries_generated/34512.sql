WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RecursiveCTE AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) + recursive.nation_count
    FROM 
        region r
    JOIN 
        RecursiveCTE recursive ON r.r_regionkey = recursive.r_regionkey
    WHERE 
        recursive.nation_count < 10
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(s.s_acctbal) AS max_supplier_acctbal
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    fr.p_partkey,
    fr.p_name,
    fr.total_revenue,
    fr.order_count,
    r.nation_count,
    fr.max_supplier_acctbal
FROM 
    FinalResults fr
JOIN 
    RecursiveCTE r ON fr.p_partkey % r.nation_count = 0
WHERE 
    fr.total_revenue > (SELECT AVG(total_revenue) FROM FinalResults)
ORDER BY 
    fr.total_revenue DESC
LIMIT 10;
