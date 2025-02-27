WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM supplier s
    JOIN SupplierCTE ct ON s.s_suppkey = ct.s_suppkey
    WHERE ct.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ord,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT p.p_name, ps.ps_availqty, SUM(os.total_revenue) AS total_order_value,
       rn.r_name, s.s_name, c.nation_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OrderSummary os ON ps.ps_supplycost < os.total_revenue
LEFT JOIN CustomerNation c ON c.c_custkey = (SELECT o.o_custkey
                                              FROM orders o
                                              WHERE o.o_orderkey = os.o_orderkey
                                              LIMIT 1)
JOIN region rn ON c.n_nationkey = rn.r_regionkey
JOIN SupplierCTE s ON s.s_suppkey = ps.ps_suppkey
WHERE p.p_retailprice IS NOT NULL 
      AND (p.p_size BETWEEN 10 AND 20 OR ps.ps_availqty > 50)
GROUP BY p.p_name, ps.ps_availqty, rn.r_name, s.s_name, c.nation_name
HAVING SUM(os.total_revenue) > 10000
ORDER BY total_order_value DESC;
