WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, p.p_partkey, p.p_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY p.p_retailprice DESC) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
), CTE_CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, 
           CASE 
               WHEN o.o_orderstatus = 'O' THEN 'Active' 
               ELSE 'Completed' 
           END as order_status
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -3, CURRENT_DATE) 
), OrderSummary AS (
    SELECT co.c_custkey, SUM(co.o_totalprice) as total_spent, 
           COUNT(co.o_orderkey) as total_orders
    FROM CTE_CustomerOrders co
    GROUP BY co.c_custkey
), FinalReport AS (
    SELECT ss.s_suppkey, ss.s_name, ss.s_address, os.total_spent,
           os.total_orders, 
           COUNT(DISTINCT co.o_orderkey) AS customer_orders,
           SUM(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost ELSE 0 END) AS total_supply_cost
    FROM SupplyChain ss
    FULL OUTER JOIN OrderSummary os ON ss.p_partkey = (SELECT MAX(p_partkey) 
                                FROM part WHERE p_retailprice > 100) 
    LEFT JOIN lineitem li ON ss.s_suppkey = li.l_suppkey
    LEFT JOIN CTE_CustomerOrders co ON co.o_orderkey = li.l_orderkey
    GROUP BY ss.s_suppkey, ss.s_name, ss.s_address, os.total_spent, os.total_orders
)
SELECT f.s_suppkey, f.s_name, f.s_address, 
       COALESCE(f.total_spent, 0) AS total_spent, 
       COALESCE(f.total_orders, 0) AS total_orders,
       CASE WHEN f.customer_orders > 0 THEN 'Supplied' ELSE 'Not Supplied' END AS supply_status,
       ROUND(f.total_supply_cost, 2) AS total_supply_cost 
FROM FinalReport f
WHERE f.total_spent IS NOT NULL OR f.total_orders IS NOT NULL
ORDER BY f.total_spent DESC NULLS LAST
LIMIT 50;
