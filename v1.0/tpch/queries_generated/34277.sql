WITH RECURSIVE SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey, r.r_name, 
           r.r_comment, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey, r.r_name, 
           r.r_comment, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN SupplierRegion sr ON sr.s_nationkey = n.n_nationkey
    WHERE sr.s_acctbal < s.s_acctbal
),
PartStats AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT l.l_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM CustomerOrders co
    JOIN customer c ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
)
SELECT pr.p_partkey, pr.avg_supply_cost, hvc.c_name, 
       COALESCE(hvc.total_spent, 0) AS total_spent,
       sr.r_name AS supplier_region
FROM PartStats pr
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = pr.p_partkey
    ORDER BY o.o_orderdate DESC
    LIMIT 1
)
JOIN SupplierRegion sr ON sr.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = pr.p_partkey
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
WHERE pr.avg_supply_cost IS NOT NULL
ORDER BY pr.avg_supply_cost DESC, total_spent DESC;
