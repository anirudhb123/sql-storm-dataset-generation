WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS depth
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(ROUND(AVG(l.l_extendedprice), 2), 0) AS avg_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS qty_returned,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    nh.n_name AS nation_name,
    sh.supp_count AS supplier_count,
    r.o_orderdate,
    r.total_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer c ON l.l_orderkey = c.c_custkey
LEFT JOIN NationDetails nh ON s.s_nationkey = nh.n_nationkey
LEFT JOIN (SELECT DISTINCT o.o_orderkey, o.o_orderdate, os.total_revenue FROM OrderSummary os
            JOIN orders o ON os.o_orderkey = o.o_orderkey) r ON l.l_orderkey = r.o_orderkey
LEFT JOIN (SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supp_count FROM supplier s
            JOIN nation n ON s.s_nationkey = n.n_nationkey GROUP BY n.n_name) sh ON sh.n_name = nh.n_name
WHERE p.p_retailprice BETWEEN 10 AND 100
GROUP BY ps.ps_partkey, p.p_name, nh.n_name, r.o_orderdate, r.total_revenue, sh.supp_count
HAVING SUM(l.l_quantity) IS NOT NULL
ORDER BY avg_price DESC, supplier_count DESC;
