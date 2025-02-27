WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), PriceAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2
    )
), PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pa.total_supplycost,
        pa.unique_suppliers,
        CASE 
            WHEN pa.unique_suppliers > 5 THEN 'High'
            ELSE 'Low'
        END AS supplier_count_category
    FROM part p
    JOIN PriceAggregates pa ON p.p_partkey = pa.ps_partkey
)
SELECT 
    ph.o_orderkey,
    ph.o_orderdate,
    p.p_name,
    p.supplier_count_category,
    sh.s_name AS supplier_name,
    sh.level AS supplier_level,
    NULLIF(DATE_PART('year', ph.o_orderdate), 2023) AS order_year_diff
FROM HighValueOrders ph
LEFT JOIN PartSupplierDetails p ON ph.o_orderkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_name = (
        SELECT DISTINCT c.c_nationkey
        FROM customer c
        WHERE c.c_custkey = ph.o_orderkey
    )
)
WHERE ph.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND sh.s_suppkey IS NULL
ORDER BY p.p_name, ph.o_orderdate DESC;
