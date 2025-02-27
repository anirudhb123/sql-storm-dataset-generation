WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        oh.o_totalprice,
        oh.depth + 1
    FROM orders oh
    JOIN OrderHierarchy oh2 ON oh.o_orderkey = oh2.o_orderkey
    WHERE oh2.depth < 5
), 
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
LineItemSummary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_lines
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_partkey
)
SELECT 
    p.p_name,
    COALESCE(SUM(ls.total_revenue), 0) AS revenue,
    COALESCE(SUM(sp.total_cost), 0) AS supplier_cost,
    COUNT(DISTINCT oh.o_orderkey) AS order_count,
    AVG(ls.total_lines) OVER (PARTITION BY p.p_partkey) AS avg_lines_per_order,
    RANK() OVER (ORDER BY COALESCE(SUM(ls.total_revenue), 0) DESC) AS revenue_rank
FROM part p
LEFT JOIN LineItemSummary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN SupplierPerformance sp ON p.p_partkey = sp.s_suppkey
LEFT JOIN orders o ON p.p_partkey = ANY (
    SELECT l.l_partkey 
    FROM lineitem l 
    WHERE l.l_orderkey = o.o_orderkey
)
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
GROUP BY p.p_partkey, p.p_name
ORDER BY revenue DESC, supplier_cost ASC;
