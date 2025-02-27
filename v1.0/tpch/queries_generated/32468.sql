WITH RECURSIVE OrderPath AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) as rnk
      FROM orders
     WHERE o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_availqty) AS total_avail_qty,
           AVG(ps_supplycost) AS avg_supply_cost, 
           COUNT(DISTINCT ps_suppkey) AS supplier_count
      FROM partsupp
     GROUP BY ps_partkey
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, s.s_name, sp.total_avail_qty,
           sp.avg_supply_cost, 
           CASE WHEN avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp) 
                THEN 'Below Average' 
                ELSE 'Above Average' END AS cost_category
      FROM part p
      JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
      INNER JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
      FROM customer c
      JOIN orders o ON c.c_custkey = o.o_custkey
     GROUP BY c.c_custkey, c.c_name
     HAVING SUM(o.o_totalprice) > 10000
)
SELECT tp.c_name, tp.total_spent, p.p_name, p.total_avail_qty, p.avg_supply_cost,
       COALESCE(p.cost_category, 'N/A') AS cost_category
  FROM TopCustomers tp
  LEFT JOIN PartSupplierDetails p ON tp.c_custkey = (SELECT c_nationkey FROM customer WHERE c_custkey = tp.c_custkey)
 WHERE tp.customer_rank <= 10
 ORDER BY tp.total_spent DESC, p.avg_supply_cost ASC;
