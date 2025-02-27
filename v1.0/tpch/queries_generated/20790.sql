WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal IS NOT NULL
),
NationSummary AS (
    SELECT n_name, COUNT(DISTINCT s_suppkey) AS total_suppliers,
           SUM(s_acctbal) AS total_acctbal, AVG(s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY n.n_name
),
TopRegions AS (
    SELECT r.r_name,
           RANK() OVER (ORDER BY SUM(ps_supplycost) DESC) AS region_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_name
    HAVING SUM(ps_supplycost) > 10000
)
SELECT 
    n.n_name, 
    nh.total_suppliers, 
    nh.avg_acctbal,
    tr.r_name,
    CASE 
        WHEN nh.total_suppliers IS NULL THEN 'No Suppliers'
        ELSE CAST(nh.total_suppliers AS VARCHAR) || ' Suppliers'
    END AS supplier_count,
    SUM(CASE 
            WHEN l.l_discount BETWEEN 0.05 AND 0.20 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS discount_prices,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM NationSummary nh
LEFT JOIN nation n ON nh.n_name = n.n_name
LEFT JOIN orders o ON o.o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey)
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN TopRegions tr ON n.n_regionkey = tr.r_regionkey
GROUP BY n.n_name, nh.total_suppliers, nh.avg_acctbal, tr.r_name
HAVING SUM(l.l_extendedprice * l.l_quantity) IS NOT NULL AND nh.total_suppliers > 5
ORDER BY supplier_count DESC, region_rank;
