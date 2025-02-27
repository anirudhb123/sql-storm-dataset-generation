WITH RECURSIVE SuppHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SuppHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

TotalSales AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM lineitem
    GROUP BY l_orderkey
),

CustomerStatus AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(COALESCE(o.o_totalprice, 0)) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),

RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate,
           DENSE_RANK() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),

SupplierAggregate AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost, 
           SUM(ps.ps_availqty) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)

SELECT c.c_name AS customer_name, 
       cs.order_count AS total_orders, 
       cs.total_spent AS total_spent,
       s.s_name AS supplier_name, 
       sa.supplier_count,
       sa.avg_supply_cost,
       RANK() OVER (PARTITION BY cs.order_count ORDER BY cs.total_spent DESC) AS spending_rank,
       RANK() OVER (PARTITION BY sa.supplier_count ORDER BY sa.total_available DESC) AS supplier_rank
FROM CustomerStatus cs
JOIN SupplierAggregate sa ON sa.supplier_count > 0
LEFT JOIN supplier s ON sa.supplier_count = s.s_nationkey
JOIN RankedOrders ro ON cs.order_count > 3
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC, sa.avg_supply_cost ASC
LIMIT 50;
