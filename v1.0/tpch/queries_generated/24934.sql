WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        CAST(o.o_orderkey AS VARCHAR) AS order_chain
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        oh.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT(oh.order_chain, '->', CAST(o.o_orderkey AS VARCHAR))
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderkey <> oh.o_orderkey AND o.o_orderstatus = 'O'
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availability,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 100
),
SalesData AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    MAX(COALESCE(sd.total_sales, 0)) AS max_sales,
    COUNT(DISTINCT fp.p_partkey) AS part_count,
    r.r_name,
    n.n_name,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY MAX(sd.total_sales) DESC) AS region_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN FilteredParts fp ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey))
LEFT JOIN SalesData sd ON sd.l_orderkey IN (SELECT o.o_orderkey FROM OrderHierarchy oh JOIN orders o ON oh.o_orderkey = o.o_orderkey)
GROUP BY r.r_regionkey, n.n_name
HAVING AVG(sd.total_sales) IS NOT NULL OR COUNT(DISTINCT fp.p_partkey) > 2
ORDER BY region_rank, r.r_name DESC;
