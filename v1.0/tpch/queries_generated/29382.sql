WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' ', n.n_name) AS supplier_full_name,
        CASE
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance'
        END AS balance_category
    FROM supplier s 
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_name, ' (', p.p_size, ')') AS part_description
    FROM part p
),
OrderLineInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    si.supplier_full_name,
    si.balance_category,
    pi.part_description,
    oli.o_orderdate,
    oli.lineitem_count,
    oli.total_extended_price
FROM SupplierInfo si
JOIN PartInfo pi ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pi.p_partkey LIMIT 1)
JOIN OrderLineInfo oli ON oli.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = si.nation_name LIMIT 1))
WHERE si.balance_category = 'High Balance'
ORDER BY oli.total_extended_price DESC, si.supplier_full_name ASC;
