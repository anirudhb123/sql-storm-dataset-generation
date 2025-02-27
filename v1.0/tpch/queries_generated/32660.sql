WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 5000
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
    SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.*, ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rn
    FROM CustomerOrderStats c
    WHERE c.order_count > 5
)
SELECT c.c_name AS Customer_Name,
       ths.s_name AS Top_Supplier_Name,
       p.p_name AS Part_Name,
       ps.total_available AS Total_Available_Quantity,
       ps.avg_supply_cost AS Average_Supply_Cost,
       c.total_spent AS Total_Spent_By_Customer,
       CASE WHEN c.order_count > 10 THEN 'VIP' ELSE 'Regular' END AS Customer_Type
FROM TopCustomers c
FULL OUTER JOIN Supplier s ON c.c_nationkey = s.s_nationkey
FULL OUTER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
JOIN lineitem li ON li.l_suppkey = s.s_suppkey
JOIN part p ON li.l_partkey = p.p_partkey
JOIN PartSupplierStats ps ON p.p_partkey = ps.p_partkey
WHERE c.total_spent > 1000
   OR ps.avg_supply_cost < 50.00
ORDER BY c.c_name, p.p_name;
