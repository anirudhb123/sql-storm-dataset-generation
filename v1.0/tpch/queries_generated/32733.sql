WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 5000
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_discount > 0.05
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DATE_PART('year', AGE(o.o_orderdate)) AS order_age
    FROM orders o
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
),
TopPartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_availqty) FROM partsupp
    )
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FinalReport AS (
    SELECT ph.s_name, rn.l_orderkey, rn.l_partkey,
           rn.l_quantity, rn.l_extendedprice, ro.order_age,
           COALESCE(ts.total_supply_cost, 0) AS total_supply_cost
    FROM RankedLineItems rn
    LEFT JOIN RecentOrders ro ON rn.l_orderkey = ro.o_orderkey
    LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = rn.l_partkey
    LEFT JOIN TopPartSuppliers ts ON ts.ps_partkey = rn.l_partkey
    WHERE ro.order_age < 1 AND rn.rn <= 5
)
SELECT f.s_name, f.l_orderkey, f.l_partkey, f.l_quantity, f.l_extendedprice, 
       f.order_age, SUM(f.total_supply_cost) OVER (PARTITION BY f.l_orderkey) AS total_order_supply_cost
FROM FinalReport f
ORDER BY f.l_orderkey, f.l_extendedprice DESC
LIMIT 100;
