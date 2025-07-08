
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
)
SELECT 
    n.n_name AS nation_name,
    p.p_name AS part_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    LISTAGG(DISTINCT CASE WHEN ps.ps_supplycost IS NULL THEN 'Not supplied' ELSE 'Supplied' END, ', ') WITHIN GROUP (ORDER BY CASE WHEN ps.ps_supplycost IS NULL THEN 'Not supplied' ELSE 'Supplied' END) AS supply_status,
    MAX(s.s_acctbal) AS max_supplier_balance 
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = ps.ps_suppkey AND s.supplier_rank = 1
JOIN 
    part p ON p.p_partkey = l.l_partkey 
WHERE 
    (n.n_name IS NOT NULL OR p.p_type IS NOT NULL) 
    AND (l.l_returnflag IN ('R', 'N') OR l.l_discount BETWEEN 0 AND 0.1)
GROUP BY 
    n.n_name, p.p_name, s.s_acctbal 
HAVING 
    SUM(l.l_quantity) > 0 
    AND MAX(l.l_discount) IS NOT DISTINCT FROM 0 
    AND COUNT(DISTINCT s.s_suppkey) IS NOT NULL 
ORDER BY 
    p.p_name ASC;
