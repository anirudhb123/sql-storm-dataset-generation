WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, p_comment,
           ROW_NUMBER() OVER (PARTITION BY p_size ORDER BY p_retailprice DESC) AS size_rank
    FROM part
    WHERE p_retailprice IS NOT NULL
), RankedSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal,
           RANK() OVER (ORDER BY s_acctbal DESC) AS rank_acctbal
    FROM supplier
    WHERE s_acctbal IS NOT NULL
), OrderDetails AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           AVG(l_quantity) AS avg_qty, COUNT(DISTINCT l_partkey) AS count_parts
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey, o_custkey
), NationalCustomer AS (
    SELECT c.c_custkey, c.c_name, n.n_name, c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
), SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT t.c_name, t.r_name, rp.p_name, rp.p_retailprice, rc.total_revenue,
       (SELECT COUNT(DISTINCT l_partkey) FROM lineitem li WHERE li.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = t.c_custkey)) AS part_count,
       CASE WHEN rc.total_revenue > 10000 THEN 'High' ELSE 'Low' END AS revenue_category,
       CASE WHEN rp.size_rank = 1 THEN 'Top Retail' ELSE 'Other' END AS retail_status
FROM NationalCustomer t
JOIN RankedSuppliers rs ON t.c_custkey = rs.s_suppkey
LEFT JOIN RecursivePart rp ON rp.p_partkey = (SELECT ps.ps_partkey FROM SupplierParts ps WHERE ps.ps_suppkey = rs.s_suppkey ORDER BY ps.total_supply_cost DESC LIMIT 1)
JOIN OrderDetails rc ON t.c_custkey = rc.o_custkey
WHERE rp.p_size IS NOT NULL AND rc.total_revenue IS NOT NULL
ORDER BY t.c_name, rp.p_retailprice DESC
OFFSET 5 ROWS FETCH NEXT 20 ROWS ONLY;
