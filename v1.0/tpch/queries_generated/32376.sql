WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, o_orderstatus, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.totalprice, o.orderdate, o.orderstatus, oh.level + 1
    FROM orders AS o
    INNER JOIN OrderHierarchy AS oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
CteOrderDetails AS (
    SELECT 
        oh.o_orderkey,
        oh.o_custkey,
        oh.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY oh.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM OrderHierarchy AS oh
    JOIN lineitem AS l ON l.l_orderkey = oh.o_orderkey
    GROUP BY oh.o_orderkey, oh.o_custkey, oh.o_totalprice
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COALESCE(od.revenue, 0) AS customer_revenue,
    COALESCE(sr.total_cost, 0) AS supplier_cost,
    r.r_name AS region_name,
    COUNT(DISTINCT od.o_orderkey) AS order_count
FROM customer AS c
LEFT JOIN CteOrderDetails AS od ON c.c_custkey = od.o_custkey AND od.rn = 1
LEFT JOIN nation AS n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region AS r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierRevenue AS sr ON sr.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)))
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000.00
GROUP BY c.c_custkey, c.c_name, c.c_acctbal, r.r_name, od.revenue, sr.total_cost
HAVING COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY customer_revenue DESC, supplier_cost ASC;
