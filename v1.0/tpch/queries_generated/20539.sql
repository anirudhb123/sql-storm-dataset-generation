WITH RecursivePartSupplier AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost, 
        1 AS level
    FROM 
        partsupp
    WHERE 
        ps_availqty > 0

    UNION ALL

    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty - r.ps_availqty AS adjusted_availqty,
        ps.ps_supplycost,
        level + 1
    FROM 
        partsupp ps
    JOIN 
        RecursivePartSupplier r 
    ON 
        ps.ps_partkey = r.ps_partkey 
        AND ps.ps_availqty > r.adjusted_availqty
)

SELECT 
    p.p_name, 
    s.s_name, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    SUM(l.l_quantity) FILTER (WHERE l.l_returnflag = 'R') AS returned_quantity,
    MAX(l.l_discount) OVER (PARTITION BY l.l_orderkey) AS max_discount,
    MIN(l.l_tax) OVER (PARTITION BY l.l_orderkey) AS min_tax,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    CASE 
        WHEN p.p_size IS NULL THEN 'Unknown Size'
        WHEN p.p_size BETWEEN 1 AND 50 THEN 'Small'
        WHEN p.p_size BETWEEN 51 AND 100 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    RecursivePartSupplier r ON p.p_partkey = r.ps_partkey
WHERE 
    p.p_mfgr = 'Manufacturer#1'
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10
OFFSET 5;
