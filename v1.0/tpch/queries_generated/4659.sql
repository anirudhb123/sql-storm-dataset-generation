WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, MAX(ps.ps_supplycost) AS max_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING MAX(ps.ps_supplycost) > 100.00
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, 
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT cs.c_name, cs.total_spent, cs.total_orders,
       ss.s_name, ss.total_parts, ss.total_available, ss.total_value,
       np.p_name, np.max_supply_cost, 
       ns.n_name, ns.total_acctbal
FROM CustomerOrders cs
JOIN SupplierStats ss ON cs.total_spent > 5000
LEFT JOIN HighValueParts np ON ss.total_parts > 10
LEFT JOIN NationSupplier ns ON ns.total_acctbal IS NOT NULL
ORDER BY cs.total_spent DESC, ss.total_value ASC
LIMIT 100;
