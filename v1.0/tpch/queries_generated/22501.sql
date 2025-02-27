WITH RECURSIVE OrderCounts AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count
    FROM orders
    GROUP BY o_custkey
    HAVING COUNT(o_orderkey) > 0
),
RankedSuppliers AS (
    SELECT s_suppkey, s_name, 
           DENSE_RANK() OVER (ORDER BY SUM(ps_supplycost) DESC) AS rank_cost
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_suppkey, s_name
),
HighValueOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS order_rank
    FROM orders
    WHERE o_orderstatus = 'F' AND o_totalprice > (
        SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'F'
    )
),
PartStats AS (
    SELECT p_partkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
           RANK() OVER (ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM lineitem
    JOIN part ON l_partkey = p_partkey
    GROUP BY p_partkey
),
CustomerSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
)
SELECT ns.n_name, 
       COALESCE(osc.order_count, 0) AS total_orders,
       COALESCE(sf.rank_cost, 'No suppliers') AS supplier_rank,
       COALESCE(ps.total_sales, 0) AS sales_total,
       cs.total_spent AS customer_spending
FROM nation ns
LEFT JOIN OrderCounts osc ON ns.n_nationkey = osc.o_custkey
LEFT JOIN RankedSuppliers sf ON sf.rank_cost <= 3
LEFT JOIN PartStats ps ON ps.p_partkey IN (
    SELECT p_partkey FROM partsupp WHERE ps_supplycost < 100
)
LEFT JOIN CustomerSales cs ON cs.c_custkey = osc.o_custkey
WHERE ns.r_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%East%')
  AND (cs.total_spent IS NOT NULL OR osc.order_count > 10)
ORDER BY ns.n_name, total_orders DESC NULLS LAST;
