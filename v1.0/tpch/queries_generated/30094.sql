WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2024-01-01'
), LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(*) AS lineitem_count,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
), NationAggregates AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_partkey, p.p_name, p.p_brand, 
       COALESCE(s.s_name, 'Unknown') AS supplier_name,
       COALESCE(ls.total_sales, 0) AS total_sales,
       na.total_acctbal AS nation_total_acctbal,
       na.supplier_count AS nation_supplier_count,
       ROW_NUMBER() OVER (PARTITION BY na.n_name ORDER BY ls.total_sales DESC) AS sales_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN LineItemSummary ls ON ls.l_orderkey = ps.ps_partkey
LEFT JOIN NationAggregates na ON s.s_nationkey = na.n_nationkey
WHERE p.p_retailprice > 50
  AND (na.total_acctbal IS NULL OR na.supplier_count > 2)
ORDER BY p.p_partkey, ls.total_sales DESC;
