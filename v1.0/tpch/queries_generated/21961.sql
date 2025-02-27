WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier) AND sh.level < 5
),
MaxSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ranking
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_supplycost) AS total_supplycost,
           MAX(ps.ps_availqty) AS max_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    ph.s_name AS supplier_name,
    ps.total_supplycost,
    ps.max_avail_qty,
    COALESCE(ms.total_sales, 0) AS total_sales,
    CASE 
        WHEN ms.ranking = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_type
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy ph ON ph.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = (SELECT MIN(s_nationkey) FROM supplier))
LEFT JOIN MaxSales ms ON ms.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE p.p_retailprice IS NOT NULL
AND (p.p_brand = 'Brand#45' OR p.p_container IS NULL)
ORDER BY total_sales DESC NULLS LAST;
