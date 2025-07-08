
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        0 AS level
    FROM supplier AS s
    WHERE s.s_comment LIKE '%important%'
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM supplier AS s
    JOIN SupplierHierarchy AS sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM orders AS o
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT 
        n.n_name AS nation_name,
        COALESCE(SUM(os.total_revenue), 0) AS total_revenue
    FROM nation AS n
    LEFT JOIN OrderSummary AS os ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer AS c JOIN orders AS o ON c.c_custkey = o.o_orderkey WHERE o.o_orderkey % 5 = n.n_nationkey)
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available,
    MAX(nr.total_revenue) AS max_revenue,
    COUNT(DISTINCT sh.s_suppkey) AS direct_suppliers,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'F') AS finished_orders
FROM part AS p
JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem AS l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders AS o ON l.l_orderkey = o.o_orderkey
JOIN NationRevenue AS nr ON nr.nation_name = CAST(p.p_partkey % 25 AS STRING)
LEFT JOIN SupplierHierarchy AS sh ON sh.s_nationkey = (SELECT s_nationkey FROM supplier WHERE s_comment LIKE '%quality%')
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100 AND MAX(nr.total_revenue) > 1000
ORDER BY 
    max_revenue DESC, total_available ASC;
