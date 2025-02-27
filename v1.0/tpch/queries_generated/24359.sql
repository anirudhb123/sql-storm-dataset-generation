WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierPartCounts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_sales,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS segment_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_mktsegment
),
NationSupplier AS (
    SELECT 
        n.n_name, 
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(s.s_suppkey) AS supplier_count,
        CASE 
            WHEN SUM(s.s_acctbal) IS NULL THEN 'No Account Balance'
            ELSE 'Account Balance Present'
        END AS balance_status
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.o_orderkey,
    r.revenue,
    n.n_name,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
    cs.c_mktsegment,
    cs.total_sales,
    COALESCE(ns.total_acctbal, 0) AS total_nation_acctbal,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY r.revenue DESC) AS revenue_rank_within_nation,
    CASE 
        WHEN r.revenue IS NULL OR n.supplier_count = 0 THEN 'No Revenue / Suppliers'
        ELSE 'Valid Revenue / Suppliers'
    END AS validation_status
FROM RankedOrders r
JOIN SupplierPartCounts ps ON r.o_orderkey = ps.p_partkey
JOIN NationSupplier ns ON ps.supplier_count = ns.supplier_count
JOIN CustomerSegment cs ON cs.segment_rank < 5
LEFT JOIN nation n ON n.n_nationkey = ns.supplier_count
WHERE ps.supplier_count > 0
GROUP BY r.o_orderkey, n.n_name, cs.c_mktsegment, cs.total_sales, ns.total_acctbal
HAVING SUM(r.revenue) > 10000
ORDER BY r.revenue DESC, n.n_name;
