WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey,
           sh.level + 1
    FROM supplier s
    JOIN nation n ON s.n_nationkey = n.n_nationkey
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE sh.level < 10
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           o.o_shippriority,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
MaxLineItems AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, 
           ps.ps_availqty, 
           COALESCE(NULLIF(SUM(DISTINCT l.l_quantity), 0), 0) AS total_quantity_sold
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey 
    GROUP BY p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, ps.ps_availqty
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    AVG(sh.level) AS avg_supplier_level,
    SUM(od.o_totalprice) AS total_order_value,
    SUM(pd.total_quantity_sold) AS total_quantity_sold
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.n_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN RankedOrders od ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = od.o_custkey)
LEFT JOIN PartDetails pd ON pd.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
GROUP BY n.n_name
HAVING AVG(sh.level) > 1 AND COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_order_value DESC
LIMIT 10;
