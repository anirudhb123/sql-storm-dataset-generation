WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY ns.n_regionkey ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), 
SupplierCount AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    r.r_name AS region,
    sc.supplier_count,
    H.total_order_value,
    CASE 
        WHEN H.total_order_value IS NOT NULL THEN 'High Value'
        ELSE 'Low Value'
    END AS order_type
FROM 
    part p
LEFT JOIN 
    SupplierCount sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    HighValueOrders H ON l.l_orderkey = H.o_orderkey
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT ns.n_nationkey 
                                   FROM supplier s1 
                                   JOIN RankedSuppliers s2 ON s1.s_suppkey = s2.s_suppkey
                                   WHERE s2.ranking = 1 AND s1.s_acctbal IS NOT NULL 
                                   LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (p.p_size > 10 OR p.p_type LIKE '%widget%')
    AND (sc.supplier_count IS NULL OR sc.supplier_count < 3)
ORDER BY 
    p.p_partkey, H.total_order_value DESC NULLS LAST;
