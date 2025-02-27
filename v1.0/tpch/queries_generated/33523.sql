WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
), PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT nh.n_name, rh.r_name, COUNT(DISTINCT co.c_custkey) AS customer_count,
       SUM(roi.o_totalprice) AS total_revenue,
       AVG(sp.hierarchy_level) AS avg_supplier_hierarchy,
       STRING_AGG(DISTINCT p.p_name) AS part_names
FROM nation nh
LEFT JOIN region rh ON nh.n_regionkey = rh.r_regionkey
LEFT JOIN customer co ON nh.n_nationkey = co.c_nationkey
LEFT JOIN RankedOrders roi ON co.c_custkey = roi.o_custkey
LEFT JOIN SupplierHierarchy sp ON co.c_nationkey = sp.s_nationkey
LEFT JOIN PartSupplierInfo ps ON ps.p_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_availqty > (
        SELECT AVG(ps_availqty)
        FROM partsupp
        WHERE ps_supplycost < 500
    )
)
WHERE nh.n_name LIKE '%%' OR rh.r_name IS NULL
GROUP BY nh.n_name, rh.r_name
HAVING COALESCE(SUM(roi.o_totalprice), 0) > 10000
ORDER BY customer_count DESC, total_revenue DESC;
