WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartDetails AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 5000 AND o.o_orderdate >= '2023-01-01'
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FinalReport AS (
    SELECT 
        n.n_name AS nation,
        p.p_name AS part_name,
        COALESCE(SUM(ld.l_extendedprice * (1 - ld.l_discount)), 0) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COUNT(DISTINCT l.l_orderkey) AS total_lineitems,
        sh.level AS supplier_level
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN HighValueOrders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
    LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
    WHERE p.p_retailprice > 100.00
    GROUP BY n.n_name, p.p_name, sh.level
)
SELECT 
    f.nation,
    f.part_name,
    f.revenue,
    f.total_orders,
    f.total_lineitems,
    CASE 
        WHEN f.revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sale_status
FROM FinalReport f
ORDER BY f.revenue DESC, f.nation, f.part_name;
