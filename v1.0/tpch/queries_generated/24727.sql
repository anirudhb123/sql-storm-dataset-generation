WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS VARCHAR(100)) AS hierarchy
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CAST(CONCAT(sh.hierarchy, ' > ', s.s_name) AS VARCHAR(100))
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),

PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice < (
        SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10
    )
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
),

RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderpriority LIKE '5%'
)

SELECT rh.hierarchy, pd.p_name, pd.total_supply_cost, co.order_count, 
       COUNT(DISTINCT ro.o_orderkey) AS total_orders,
       STRING_AGG(DISTINCT co.c_name, ', ') AS customer_names
FROM SupplierHierarchy rh
JOIN PartDetails pd ON rh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
JOIN CustomerOrders co ON co.order_count > 5
LEFT JOIN RankedOrders ro ON co.c_custkey = ro.o_orderkey
WHERE pd.total_supply_cost IS NOT NULL AND pd.unique_suppliers > 3
GROUP BY rh.hierarchy, pd.p_name, pd.total_supply_cost, co.order_count
HAVING SUM(CASE WHEN co.order_count IS NULL THEN 1 ELSE 0 END) = 0 OR COUNT(ro.o_orderkey) > 10
ORDER BY pd.total_supply_cost DESC, rh.hierarchy;
