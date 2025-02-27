WITH StringAggregations AS (
    SELECT 
        p_brand,
        COUNT(DISTINCT p_partkey) AS unique_parts,
        MAX(LENGTH(p_name)) AS max_name_length,
        MIN(LENGTH(p_container)) AS min_container_length,
        STRING_AGG(DISTINCT p_comment, '; ') AS all_comments
    FROM part
    WHERE p_type LIKE '%steel%'
    GROUP BY p_brand
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.nationkey,
        n.n_name AS nation_name,
        n.n_comment AS nation_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN ('USA', 'Germany')
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        o.o_comment,
        COUNT(l.l_linenumber) AS line_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, c.c_name, o.o_orderstatus, o.o_orderdate, o.o_totalprice, o.o_comment
),
BenchmarkedResults AS (
    SELECT 
        s.s_name,
        sd.unique_parts,
        od.line_count,
        sd.nation_name,
        od.o_orderdate,
        od.o_orderstatus,
        od.o_totalprice
    FROM SupplierDetails sd
    JOIN StringAggregations sd ON sd.nationkey = sd.n_nationkey
    JOIN OrderDetails od ON sd.s_suppkey = od.o_custkey
)
SELECT 
    b.s_name,
    b.unique_parts,
    b.line_count,
    b.nation_name,
    b.o_orderdate,
    b.o_orderstatus,
    b.o_totalprice
FROM BenchmarkedResults b
ORDER BY b.o_orderdate DESC, b.unique_parts DESC;
