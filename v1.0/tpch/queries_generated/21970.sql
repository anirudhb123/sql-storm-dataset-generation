WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, s.s_nationkey, level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -3, CURRENT_DATE)
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, 
           l.l_discount, 
           CASE 
               WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) 
               ELSE l.l_extendedprice 
           END AS effective_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
AggregatedData AS (
    SELECT p.p_partkey, SUM(f.effective_price * l.l_quantity) AS total_revenue, COUNT(DISTINCT c.c_custkey) AS num_customers
    FROM part p
    JOIN FilteredLineItems f ON p.p_partkey = f.l_partkey
    JOIN orders o ON f.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY p.p_partkey
)
SELECT r.r_name, 
       COALESCE(SUM(a.total_revenue), 0) AS total_revenue, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       AVG(a.num_customers) OVER () AS avg_customers_per_part
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN AggregatedData a ON s.s_suppkey = (SELECT TOP 1 s2.s_suppkey FROM supplier s2 WHERE s2.s_acctbal > 3000 ORDER BY s2.s_acctbal DESC)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY r.r_name
ORDER BY total_revenue DESC, r.r_name ASC;
