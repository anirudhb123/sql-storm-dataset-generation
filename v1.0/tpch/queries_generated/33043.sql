WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)

SELECT 
    rh.s_name AS Supplier_Name,
    tc.c_name AS Top_Customer,
    ps.p_name AS Part_Name,
    rs.r_name AS Region_Name,
    tc.total_spent AS Total_Spent,
    p.total_supply_cost AS Total_Supply_Cost,
    rh.level AS Supplier_Level,
    rs.nation_count AS Nation_Count,
    rs.total_supplier_balance AS Total_Supplier_Balance
FROM SupplierHierarchy rh
JOIN TopCustomers tc ON rh.s_nationkey = tc.c_custkey
JOIN PartSupplierDetails ps ON ps.total_supply_cost > 50000
JOIN RegionStats rs ON rh.s_nationkey = rs.nation_count
WHERE rh.level <= 3
  AND tc.total_spent > 1000
ORDER BY rh.s_name, tc.total_spent DESC, ps.total_supply_cost ASC;
