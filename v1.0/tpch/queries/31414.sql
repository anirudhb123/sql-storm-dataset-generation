
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, NULL AS parent_suppkey, s.s_acctbal, s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.s_suppkey AS parent_suppkey, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.parent_suppkey
),
AggregatedSales AS (
    SELECT
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_mktsegment
),
TopSuppliers AS (
    SELECT
        sh.s_suppkey,
        sh.s_name,
        sh.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY sh.s_acctbal DESC) AS rank
    FROM SupplierHierarchy sh
)
SELECT
    r.r_name,
    n.n_name,
    ps.ps_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE l.l_shipdate < DATE '1998-10-01' - INTERVAL '1 year'
GROUP BY r.r_name, n.n_name, ps.ps_partkey, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
