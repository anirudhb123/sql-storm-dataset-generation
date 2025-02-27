WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_receiptdate DESC) AS lineitem_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT co.c_custkey, co.c_name, co.order_count, co.total_spent,
       sp.s_name AS top_supplier, sp.total_supply_cost,
       la.total_revenue, la.return_count
FROM CustomerOrders co
LEFT JOIN SupplierParts sp ON co.order_count > 5
LEFT JOIN LineItemAnalysis la ON la.l_orderkey IN (
     SELECT o.o_orderkey
     FROM orders o 
     WHERE o.o_orderstatus = 'O' 
       AND o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
)
WHERE co.total_spent IS NOT NULL
  AND (co.order_count > 0 OR sp.total_supply_cost IS NOT NULL)
  AND COALESCE(sp.total_supply_cost, 0) > 10000
ORDER BY co.total_spent DESC, la.return_count ASC;
