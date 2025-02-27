WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_size, 1 AS depth
    FROM part
    WHERE p_size >= 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_size, ph.depth + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size = ph.p_size - 1
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    n.n_name AS nation,
    p.p_name,
    ps.total_available,
    COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue,
    STRING_AGG(DISTINCT c.c_name) AS customer_names,
    MAX(oo.o_orderdate) AS last_order_date
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem lo ON lo.l_partkey = p.p_partkey
LEFT JOIN RankedOrders oo ON lo.l_orderkey = oo.o_orderkey
LEFT JOIN customer c ON oo.o_custkey = c.c_custkey
WHERE p.p_mfgr LIKE 'Manufacturer%' 
AND lo.l_shipdate >= '2023-01-01'
AND (n.n_name IS NOT NULL OR r.r_name IS NULL)
GROUP BY r.r_name, n.n_name, p.p_name, ps.total_available
HAVING total_revenue > 1000
ORDER BY total_revenue DESC
LIMIT 10;
