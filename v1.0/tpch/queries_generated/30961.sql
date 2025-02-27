WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice * 0.9 AS o_totalprice, o.o_orderstatus, h.level + 1
    FROM orders o
    JOIN OrderHierarchy h ON o.o_orderkey = h.o_orderkey
    WHERE h.level < 5
),
CustomerStats AS (
    SELECT c.c_custkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent,
           CASE 
               WHEN SUM(o.o_totalprice) IS NULL THEN 'No Orders'
               ELSE CAST(SUM(o.o_totalprice) AS VARCHAR)
           END AS order_summary
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierPartStats AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_supply_cost,
           STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_mfgr, ')'), ', ') AS part_names
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
)
SELECT c.c_name, cs.total_orders, cs.total_spent, cs.order_summary,
       sp.s_suppkey, sp.total_available, sp.average_supply_cost, sp.part_names,
       ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY cs.total_spent DESC) AS rn,
       COALESCE(sp.average_supply_cost, 0) AS safe_supply_cost,
       CASE 
           WHEN cs.total_spent > 1000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_type
FROM CustomerStats cs
FULL OUTER JOIN SupplierPartStats sp ON cs.total_orders > 0 OR sp.total_available > 0
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cs.c_custkey)
WHERE r.r_name LIKE 'North%'
AND (sp.total_available IS NOT NULL OR cs.total_spent IS NOT NULL)
ORDER BY cs.total_spent DESC NULLS LAST;
