WITH StringAggregates AS (
    SELECT
        p_brand,
        COUNT(DISTINCT p_partkey) AS part_count,
        STRING_AGG(DISTINCT p_name, ', ') AS part_names,
        STRING_AGG(DISTINCT p_comment, '; ') AS comments_overview
    FROM part
    GROUP BY p_brand
),
NationSupplier AS (
    SELECT
        n.n_name,
        s.s_name,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE LENGTH(s.s_comment) > 50
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        STRING_AGG(DISTINCT CONCAT(l.l_linestatus, ' (', l.l_quantity, ')'), ', ') AS lineitem_summary
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    sa.p_brand,
    sa.part_count,
    sa.part_names,
    ns.n_name AS supplier_nation,
    ns.s_name AS supplier_name,
    od.total_sales,
    od.lineitem_summary
FROM StringAggregates sa
JOIN NationSupplier ns ON ns.s_comment LIKE '%' || sa.p_brand || '%'
JOIN OrderDetails od ON od.total_sales > 10000
ORDER BY sa.part_count DESC, ns.n_name;
