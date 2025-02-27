WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RankingOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY DATE_PART('year', o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, 
           COUNT(l.l_orderkey) AS item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_mktsegment = 'AUTOMOBILE') AS automobile_customers,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity,
    MAX(sh.s_acctbal) AS max_supplier_balance,
    AVG(al.total_price_after_discount) OVER (PARTITION BY DATE_PART('month', o.o_orderdate)) AS avg_monthly_sales,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN AggregatedLineItems al ON o.o_orderkey = al.l_orderkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
GROUP BY p.p_partkey, p.p_name, p.p_retailprice, r.r_name
HAVING SUM(ps.ps_availqty) > 1000
ORDER BY p.p_partkey;
