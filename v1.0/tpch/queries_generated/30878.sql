WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
),
TopRegions AS (
    SELECT n.n_nationkey, r.r_name, SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_name
    HAVING SUM(s.s_acctbal) > 500000.00
)
SELECT COALESCE(rc.cust_name, 'Unknown Customer') AS customer_name,
       COALESCE(pr.p_name, 'Unknown Part') AS part_name,
       COALESCE(rg.r_name, 'Unknown Region') AS region_name,
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(ps.ps_availqty) AS total_available_quantity,
       AVG(ps.ps_supplycost) AS average_supply_cost
FROM CustomerOrders co
FULL OUTER JOIN PartSupplier ps ON co.o_orderkey = ps.p_partkey
FULL OUTER JOIN TopRegions rg ON ps.p_partkey = rg.n_nationkey
LEFT JOIN (SELECT c.c_custkey, c.c_name AS cust_name FROM customer c) rc ON co.c_custkey = rc.c_custkey
GROUP BY rc.cust_name, pr.p_name, rg.r_name
HAVING SUM(ps.ps_availqty) IS NOT NULL
ORDER BY total_orders DESC, average_supply_cost ASC;
