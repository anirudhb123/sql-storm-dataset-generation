WITH SupplierCost AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationalSuppliers AS (
    SELECT n.n_name, SUM(sc.total_supply_cost) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    GROUP BY n.n_name
)
SELECT r.r_name,
       NVL(n.total_supply_cost, 0) AS total_supply_by_region,
       COUNT(DISTINCT cp.c_custkey) AS active_customers,
       AVG(co.total_spent) AS avg_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN NationalSuppliers ns ON n.n_name = ns.n_name
LEFT JOIN CustomerOrders co ON r.r_name = (SELECT c.c_name FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_custkey LIMIT 1)
LEFT JOIN HighValueParts hp ON hp.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = n.n_nationkey)
LEFT JOIN customer cp ON cp.c_nationkey = n.n_nationkey
WHERE n.total_supply_cost IS NOT NULL OR co.total_spent > 1000
GROUP BY r.r_name, n.total_supply_cost
ORDER BY r.r_name;
