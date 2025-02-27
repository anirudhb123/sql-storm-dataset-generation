WITH RECURSIVE NationCTE AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, depth + 1
    FROM nation n
    JOIN NationCTE cte ON n.n_regionkey = cte.n_nationkey
),
SupplierInfo AS (
    SELECT s_suppkey, s_name, s_nationkey, 
           SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s_suppkey, s_name, s_nationkey
),
BestSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, si.total_supply_cost
    FROM SupplierInfo si
    JOIN supplier s ON si.s_suppkey = s.s_suppkey
    WHERE si.rn <= 3
)
SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(l.l_quantity) AS avg_quantity,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       CASE 
           WHEN c.c_acctbal IS NULL THEN 'No Balance'
           WHEN c.c_acctbal < 500 THEN 'Low Balance'
           ELSE 'Sufficient Balance'
       END AS balance_status
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE o.o_orderstatus IN ('O', 'F') AND
      EXISTS (SELECT 1 FROM BestSuppliers bs WHERE c.c_nationkey = bs.s_nationkey)
GROUP BY c.c_custkey, c.c_name
HAVING total_revenue > (SELECT AVG(total_revenue) FROM (
                            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
                            FROM lineitem
                            GROUP BY l_orderkey) avg_rev)
ORDER BY total_revenue DESC;
