WITH RECURSIVE PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > 1000
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
), CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT r.r_name, np.n_name, psp.ps_suppkey, pp.p_name, rp.total_revenue, co.total_orders
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN PartSuppliers psp ON psp.ps_suppkey IN (
      SELECT ps.ps_suppkey 
      FROM partsupp ps 
      WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%')
)
LEFT JOIN RankedParts rp ON psp.ps_partkey = rp.p_partkey 
LEFT JOIN CustomerOrders co ON co.c_custkey IN (
    SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = np.n_nationkey
)
WHERE rp.total_revenue IS NOT NULL OR co.total_orders > 0
ORDER BY r.r_name, rp.total_revenue DESC NULLS LAST, co.total_orders DESC;
