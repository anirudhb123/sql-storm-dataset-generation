WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
      AND (o.o_orderstatus IS NULL OR o.o_orderstatus <> 'C')
    GROUP BY c.c_custkey, o.o_orderkey
),
FilteredPart AS (
    SELECT p.p_partkey,
           p.p_retailprice,
           CASE 
               WHEN p.p_size IS NOT NULL THEN p.p_size * 1.1 
               ELSE 1 
           END AS adjusted_size
    FROM part p
    WHERE p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT c.c_name,
       SUM(co.total_revenue) AS total_revenue,
       COUNT(co.o_orderkey) AS total_orders,
       GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name) AS supplier_names,
       COUNT(DISTINCT CASE WHEN ps.ps_availqty IS NULL THEN 1 END) AS null_availability,
       MAX(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost END) AS highest_supply_cost,
       ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(co.total_revenue) DESC) AS nation_rank
FROM CustomerOrders co
LEFT JOIN RankedSuppliers s ON co.o_orderkey = s.s_suppkey AND s.acct_rank = 1
LEFT JOIN FilteredPart p ON p.p_partkey = co.o_orderkey
LEFT JOIN partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN customer c ON co.c_custkey = c.c_custkey
WHERE EXISTS (SELECT 1
              FROM nation n
              WHERE n.n_nationkey = c.c_nationkey AND n.n_name IS NOT NULL)
GROUP BY c.c_name
HAVING SUM(co.total_revenue) > (SELECT AVG(total_revenue) FROM CustomerOrders)
ORDER BY total_orders DESC, total_revenue ASC;
