WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS hierarchy_level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT cc.c_custkey, cc.order_count,
           DENSE_RANK() OVER (ORDER BY cc.order_count DESC) AS rank
    FROM CustomerOrderCount cc
    WHERE cc.order_count > 0
),
PartSupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT p.p_partkey, p.p_name, p.p_retailprice, 
       COALESCE(sc.total_supply_cost, 0) AS supply_cost,
       COALESCE(ts.order_count, 0) AS customer_orders,
       DATE_PART('year', o.o_orderdate) AS order_year,
       ROW_NUMBER() OVER (PARTITION BY DATE_PART('year', o.o_orderdate) ORDER BY COALESCE(ts.order_count, 0) DESC) AS order_rank
FROM part p
LEFT JOIN PartSupplierCost sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN TopCustomers ts ON ts.c_custkey = (
    SELECT c.c_custkey 
    FROM customer c
    WHERE c.c_nationkey = p.p_partkey
    LIMIT 1
)
LEFT JOIN orders o ON ts.c_custkey = o.o_custkey
WHERE (p.p_retailprice > 100.00 OR sc.total_supply_cost IS NULL)
  AND (p.p_comment LIKE '%special%' OR p.p_container IS NOT NULL)
ORDER BY order_year DESC, customer_orders DESC;