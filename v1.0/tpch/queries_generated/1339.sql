WITH SupplierRanked AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerTotalOrders AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_orders, c.total_spent
    FROM CustomerTotalOrders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerTotalOrders)
)

SELECT COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       COUNT(DISTINCT l.l_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(s.s_acctbal) AS average_balance,
       COUNT(DISTINCT CASE WHEN h.c_custkey IS NOT NULL THEN h.c_custkey END) AS high_value_customer_count
FROM lineitem l
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN HighValueCustomers h ON h.total_spent > l.l_extendedprice
GROUP BY s.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC;

