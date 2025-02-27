WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, NULL::integer AS parent_s_suppkey
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
BestProducts AS (
    SELECT ps.ps_partkey, SUM(l.l_quantity) AS total_sold, AVG(l.l_extendedprice) AS avg_price
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(l.l_quantity) > 100
),
TopNations AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    ORDER BY total_acctbal DESC
    LIMIT 5
)
SELECT
    p.p_name,
    COALESCE(TotalRevenue.total_revenue, 0) AS revenue,
    COALESCE(BestProducts.total_sold, 0) AS products_sold,
    COALESCE(BestProducts.avg_price, 0) AS average_price,
    TopNations.n_name,
    SupplierHierarchy.s_name AS supplier_name,
    SupplierHierarchy.s_acctbal
FROM part p
LEFT JOIN BestProducts ON p.p_partkey = BestProducts.ps_partkey
LEFT JOIN OrderSummary TotalRevenue ON TotalRevenue.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate > DATE '2023-06-30'
)
JOIN TopNations ON TRUE
LEFT JOIN SupplierHierarchy ON SupplierHierarchy.parent_s_suppkey IS NULL
ORDER BY revenue DESC, products_sold DESC;
