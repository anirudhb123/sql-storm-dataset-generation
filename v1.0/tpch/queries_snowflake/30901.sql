
WITH RECURSIVE RegionSupplier AS (
    SELECT 
        r.r_name AS region,
        s.s_suppkey AS supplier_id,
        s.s_name AS supplier_name,
        s.s_acctbal AS account_balance,
        1 AS level
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.n_nationkey
    
    UNION ALL

    SELECT 
        rs.region,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        rs.level + 1
    FROM 
        RegionSupplier rs
    JOIN 
        partsupp ps ON rs.supplier_id = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_account_balance,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS final_order_value,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS discounted_revenue,
    LISTAGG(DISTINCT CONCAT(s.s_name, ' (', rs.region, ')'), '; ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_info
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RegionSupplier rs ON s.s_suppkey = rs.supplier_id
WHERE 
    p.p_retailprice IS NOT NULL
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
    AND p.p_name LIKE 'Product%'
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, average_account_balance DESC
LIMIT 10;
