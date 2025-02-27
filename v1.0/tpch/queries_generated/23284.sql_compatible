
WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(CASE WHEN cs.order_count > 5 THEN cs.total_spent ELSE 0 END) AS total_high_value_customers,
       STRING_AGG(DISTINCT pa.p_name, ', ') AS available_parts,
       AVG(rs.s_acctbal) AS avg_supplier_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerStats cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN RecursiveSupplier rs ON n.n_nationkey = rs.s_nationkey AND rs.rn <= 3
LEFT JOIN PartAvailability pa ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
) 
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) >= 1 OR SUM(cs.total_spent) IS NOT NULL
ORDER BY nation_count DESC, total_high_value_customers DESC;
