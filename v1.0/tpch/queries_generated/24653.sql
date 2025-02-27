WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o 
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
), SupplierAggregation AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS segment_total
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_mktsegment
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(l.l_tax) AS total_tax,
    COALESCE(SUM(c.segment_total), 0) AS total_customer_spending,
    MAX(s.total_parts) AS max_parts_per_supplier,
    AVG(s.total_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_acctbal), ', ') AS suppliers_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerSegment c ON c.c_mktsegment = 'BUILDING' AND o.o_orderkey IS NOT NULL
WHERE r.r_name NOT LIKE 'EAST%'
AND (s.s_acctbal IS NULL OR s.s_acctbal < 100)
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
   AND MAX(s.total_supplycost) IS NOT NULL
ORDER BY total_orders DESC, total_revenue ASC;
