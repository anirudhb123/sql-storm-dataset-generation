WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.hierarchy_level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
TotalOrderValues AS (
    SELECT o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY o_custkey
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COALESCE(t.total_value, 0) AS order_total,
           RANK() OVER (ORDER BY COALESCE(t.total_value, 0) DESC) as rank
    FROM customer c
    LEFT JOIN TotalOrderValues t ON c.c_custkey = t.o_custkey
    WHERE c.c_acctbal IS NOT NULL
)
SELECT s.s_name AS supplier_name, c.c_name AS customer_name, c.order_total,
       COUNT(DISTINCT l.l_orderkey) AS order_count,
       AVG(s.s_acctbal) OVER (PARTITION BY c.c_nationkey) AS avg_supplier_balance
FROM SupplierHierarchy s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN TotalOrderValues o ON o.o_custkey = l.l_orderkey
JOIN CustomerStats c ON o.o_custkey = c.c_custkey
WHERE c.rank <= 10 AND s.hierarchy_level < 3
GROUP BY s.s_name, c.c_name, c.order_total
HAVING SUM(l.l_quantity) > 100
ORDER BY order_count DESC, c.order_total DESC;
