WITH RECURSIVE PriceCTE AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost, 
        CAST(ps_supplycost AS decimal(12,4)) * DENSE_RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost) AS adjusted_cost,
        0 AS depth
    FROM partsupp
    WHERE ps_availqty > 0

    UNION ALL

    SELECT 
        p.ps_partkey, 
        p.ps_suppkey, 
        p.ps_availqty / (1 + depth) AS ps_availqty, 
        p.ps_supplycost, 
        CAST(p.ps_supplycost AS decimal(12,4)) * DENSE_RANK() OVER (PARTITION BY p.ps_partkey ORDER BY p.ps_supplycost) / (1 + depth) AS adjusted_cost,
        depth + 1
    FROM partsupp p
    JOIN PriceCTE cte 
    ON p.ps_partkey = cte.ps_partkey AND p.ps_suppkey <> cte.ps_suppkey
    WHERE p.ps_availqty > 0 AND depth < 5
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(pcte.adjusted_cost * pcte.ps_availqty) AS supplier_value
    FROM supplier s
    JOIN PriceCTE pcte ON s.s_suppkey = pcte.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(pcte.adjusted_cost * pcte.ps_availqty) > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL
    )
),
FinalSelection AS (
    SELECT 
        n.n_name,
        SUM(fs.supplier_value) AS total_supplier_value,
        COUNT(DISTINCT fs.s_suppkey) AS unique_suppliers
    FROM FilteredSuppliers fs
    JOIN nation n ON fs.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_mfgr LIKE 'P%'))
    GROUP BY n.n_name
)
SELECT 
    n.n_name,
    COALESCE(total_supplier_value, 0) AS adjusted_total,
    unique_suppliers,
    CASE 
        WHEN unique_suppliers > 5 THEN 'Good'
        WHEN unique_suppliers BETWEEN 3 AND 5 THEN 'Fair'
        ELSE 'Limited'
    END AS supplier_rating
FROM FinalSelection n
FULL OUTER JOIN region r ON r.r_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = n.n_name) 
WHERE r.r_name IS NOT NULL OR unique_suppliers > 1
ORDER BY adjusted_total DESC, unique_suppliers ASC;
