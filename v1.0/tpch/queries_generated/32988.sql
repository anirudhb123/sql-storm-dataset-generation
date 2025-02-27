WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 10000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.total_revenue) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(nr.total_revenue, 0) AS nation_revenue,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(CASE WHEN c.c_acctbal IS NOT NULL THEN c.c_acctbal ELSE 0 END) AS total_customer_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
WHERE r.r_name LIKE '%west%'
GROUP BY r.r_name, nr.total_revenue
HAVING SUM(CASE WHEN sh.s_nationkey IS NOT NULL THEN 1 ELSE 0 END) > 5
ORDER BY nation_revenue DESC NULLS LAST;
