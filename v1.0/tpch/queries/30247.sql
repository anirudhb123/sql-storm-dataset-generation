WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)  
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE level < 3  
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
NationRegionSummary AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
)
SELECT 
    ch.c_name AS customer_name,
    ch.c_acctbal AS customer_account_balance,
    os.total_orders AS number_of_orders,
    os.total_spent AS total_spent,
    psi.p_name AS part_name,
    psi.total_supply_cost AS part_total_supply_cost,
    nrs.r_name AS region_name,
    nrs.supplier_count AS supplier_count
FROM CustomerHierarchy ch
LEFT JOIN OrderSummary os ON ch.c_custkey = os.o_custkey
JOIN PartSupplierInfo psi ON psi.total_supply_cost = (
    SELECT MAX(total_supply_cost) 
    FROM PartSupplierInfo 
    WHERE total_supply_cost < 100000  
)
JOIN NationRegionSummary nrs ON ch.c_nationkey = nrs.n_nationkey
ORDER BY ch.c_acctbal DESC, os.total_spent DESC
LIMIT 100;