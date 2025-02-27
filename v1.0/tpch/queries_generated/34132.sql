WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal < 1000 AND c.c_nationkey = 1 ORDER BY c.c_acctbal LIMIT 1)
    WHERE o.o_orderkey > oh.o_orderkey
),
RankedLineItems AS (
    SELECT l.*, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_discount) AS discount_rank
    FROM lineitem l
),
SupplierAggregates AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    c.c_name,
    co.order_count,
    co.total_spent,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Revenue'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM CustomerOrders co
JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
JOIN SupplierAggregates ps ON ps.ps_partkey = l.l_partkey
LEFT JOIN FilteredSuppliers s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
GROUP BY c.c_name, co.order_count, co.total_spent
ORDER BY total_revenue DESC 
LIMIT 10;
