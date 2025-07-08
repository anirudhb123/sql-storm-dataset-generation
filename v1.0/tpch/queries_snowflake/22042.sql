
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) 
                        FROM supplier s2 
                        WHERE s2.s_nationkey IN (SELECT n_nationkey 
                                                 FROM nation 
                                                 WHERE n_regionkey = 1)) 
)

SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN ps.ps_availqty IS NULL THEN 0 
        ELSE ps.ps_availqty 
    END) AS total_available_quantity,
    COALESCE(AVG(RS.s_acctbal), 0) AS avg_supplier_acctbal,
    CASE 
        WHEN SUM(ps.ps_supplycost) IS NULL THEN 'No Cost Data' 
        ELSE 'Cost Data Available' 
    END AS cost_data_availability
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers RS ON ps.ps_suppkey = RS.s_suppkey AND RS.rank = 1
WHERE 
    p.p_retailprice IS NOT NULL 
    AND (p.p_container IN ('BOX', 'PKG') OR p.p_size > 10) 
GROUP BY 
    p.p_name
HAVING 
    COUNT(ps.ps_suppkey) > (SELECT COUNT(*) 
                            FROM supplier 
                            WHERE s_acctbal < 500)
ORDER BY 
    avg_supplier_acctbal DESC
LIMIT 10 OFFSET (SELECT COUNT(*) 
                 FROM orders 
                 WHERE o_orderstatus = 'F') % 10;
