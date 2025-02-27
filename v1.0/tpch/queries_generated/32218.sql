WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'Africa')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
),
PartSupplierAggregate AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, o.o_orderkey
),
RankedOrders AS (
    SELECT c.c_name, cod.total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY cod.total_spent DESC) AS rank
    FROM customer c
    JOIN CustomerOrderDetails cod ON c.c_custkey = cod.c_custkey
    WHERE total_spent IS NOT NULL
)

SELECT p.p_name, p.p_brand, psa.total_availqty,
       COALESCE(r.total_spent, 0) AS region_total_spent,
       nh.n_name AS nation_name
FROM part p
LEFT JOIN PartSupplierAggregate psa ON p.p_partkey = psa.ps_partkey
FULL OUTER JOIN (
    SELECT c.c_nationkey, SUM(cod.total_spent) AS total_spent
    FROM CustomerOrderDetails cod
    JOIN customer c ON cod.c_custkey = c.c_custkey
    GROUP BY c.c_nationkey
) r ON r.c_nationkey = p.p_partkey
JOIN NationHierarchy nh ON nh.n_nationkey = p.p_partkey
WHERE p.p_retailprice > 100.00
  AND (psa.total_availqty IS NULL OR psa.total_availqty >= 10)
  AND EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.o_orderkey IN (
          SELECT distinct l.l_orderkey
          FROM lineitem l
          WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R'
      )
  )
ORDER BY p.p_name, region_total_spent DESC;
