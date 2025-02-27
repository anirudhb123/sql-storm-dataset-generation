WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_clerk ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate <= CURRENT_DATE
),
SupplierOrders AS (
    SELECT 
        l.l_orderkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE l.l_shipdate IS NOT NULL AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT so.l_orderkey) AS order_count,
        SUM(so.net_revenue) AS total_revenue
    FROM SupplierOrders so
    JOIN supplier s ON so.s_name = s.s_name
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT so.l_orderkey) > 5 OR SUM(so.net_revenue) > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_shipdate > l.l_commitdate THEN 1 ELSE 0 END) AS late_shipments,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', fs.total_revenue::text), ', ') AS supplier_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey
    )
)
WHERE r.r_name IS NOT NULL AND c.c_acctbal > 0
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 AND AVG(o.o_totalprice) < (
    SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '1 month'
)
ORDER BY customer_count DESC, total_revenue @> '1'::int;
