WITH String_Aggregation AS (
    SELECT 
        n.n_name AS nation_name,
        STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE p.p_retailprice > 100.00
    GROUP BY n.n_name
)
SELECT 
    nation_name,
    supplier_names,
    part_names,
    total_orders,
    LENGTH(supplier_names) AS supplier_list_length,
    LENGTH(part_names) AS part_list_length,
    (SELECT COUNT(*) FROM part) AS total_parts,
    (SELECT COUNT(*) FROM supplier) AS total_suppliers
FROM String_Aggregation
ORDER BY total_orders DESC;
