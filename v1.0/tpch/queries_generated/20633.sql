WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') OR o.o_orderstatus IS NULL
), PartSupplierData AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) as supp_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), RegionAnalysis AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 1
)

SELECT COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
       COALESCE(p.p_name, 'Unknown Part') AS part_name, 
       ra.r_name AS region_name,
       COALESCE(lo.order_date, '1970-01-01') AS order_date,
       COUNT(DISTINCT lo.order_id) AS total_orders,
       SUM(ps.ps_availqty) AS total_available_quantity,
       SUM(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost ELSE 0 END) AS total_supply_cost
FROM CustomerOrders co
FULL OUTER JOIN PartSupplierData ps ON co.o_orderkey = ps.ps_partkey
INNER JOIN RegionAnalysis ra ON ra.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = co.cust_nationkey LIMIT 1)
LEFT JOIN (SELECT o.o_orderkey AS order_id, o.o_orderdate AS order_date 
            FROM orders o WHERE o.o_orderstatus = 'O') lo ON co.o_orderkey = lo.order_id
GROUP BY customer_name, part_name, ra.r_name
HAVING SUM(lo.order_date IS NOT NULL) > 5 
   AND (SUM(ps.ps_availqty) < 100 OR SUM(ps.ps_supplycost) BETWEEN 500 AND 1000)
ORDER BY total_orders DESC, region_name ASC
LIMIT 25 OFFSET 10;
