WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_nationkey, ch.level + 1
    FROM customer ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND ch.level < 5
), 
TopProducts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), 
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation,
    s.s_name AS supplier_name,
    p.p_name AS product_name,
    coalesce(TopProducts.total_revenue, 0) AS product_revenue,
    coalesce(SupplierSales.supplier_revenue, 0) AS total_supplier_revenue,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY coalesce(TopProducts.total_revenue, 0) DESC) AS product_rank,
    o.o_orderdate
FROM CustomerHierarchy c
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN TopProducts ON o.o_orderkey = TopProducts.p_partkey
LEFT JOIN SupplierSales s ON s.supplier_revenue > 5000
ORDER BY c.c_name, n.n_name, product_rank;
