WITH RECURSIVE PartCosts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    UNION ALL
    SELECT pc.ps_partkey,
           pc.total_cost + CASE WHEN pc.total_cost IS NULL THEN 0 ELSE pc.total_cost END
    FROM PartCosts pc
    WHERE pc.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IS NOT NULL)
),
CustomerOrders AS (
    SELECT c.c_custkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS nation_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_mfgr,
           CASE WHEN p.p_size IS NOT NULL THEN p.p_size ELSE 0 END AS safe_size,
           CASE WHEN p.p_retailprice IS NULL THEN 0.00 ELSE p.p_retailprice END AS safe_retailprice
    FROM part p
    WHERE (p.p_size > 10 OR p.p_mfgr LIKE 'Manufacturer%')
      AND NULLEQ(p.p_comment, 'None')
),
OrderedAggregate AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
           LAG(SUM(l.l_extendedprice * (1 - l.l_discount))) OVER (ORDER BY l.l_orderkey) AS previous_order_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name AS region_name,
       SUM(COALESCE(COALESCE(pc.total_cost, 0), 0)) AS total_part_cost,
       SUM(co.order_count) AS total_orders,
       AVG(oag.total_line_value) AS average_order_value,
       MIN(CASE WHEN co.total_spent > 10000 THEN co.order_count END) AS min_orders_over_10000,
       COUNT(DISTINCT fp.p_partkey) AS unique_parts
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN PartCosts pc ON pc.ps_partkey = S.s_suppkey
LEFT JOIN CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN FilteredParts fp ON fp.p_partkey = s.s_suppkey
LEFT JOIN OrderedAggregate oag ON oag.l_orderkey = co.c_custkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT fp.p_partkey) > 5
   AND SUM(co.order_count) > 10
   AND AVG(oag.total_line_value) IS NOT NULL
ORDER BY region_name DESC;
