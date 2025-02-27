WITH RECURSIVE nested_order AS (
    SELECT o.o_orderkey, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_totalprice + (no.o_totalprice * 0.1), no.level + 1
    FROM orders o
    JOIN nested_order no ON o.o_orderkey = no.o_orderkey
    WHERE no.level < 5
), 
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
product_info AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, MAX(p.p_retailprice) AS max_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT DISTINCT
    c.c_name,
    c.c_acctbal,
    COALESCE((
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount))
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = c.c_custkey AND l.l_shipdate < current_date
    ), 0) AS total_sales,
    (SELECT COUNT(*) FROM nation n WHERE n.n_regionkey IN (
        SELECT r.r_regionkey
        FROM region r
        WHERE r.r_name LIKE '%EU%'
    )) AS nation_count,
    SUM(CASE WHEN ps.ps_availqty < 10 THEN 1 ELSE 0 END) AS low_stock_count
FROM customer c
LEFT JOIN lineitem l ON l.l_orderkey IN (
    SELECT o_orderkey FROM nested_order WHERE level <= 2
)
LEFT JOIN partsupp ps ON ps.ps_partkey = l.l_partkey
JOIN product_info pi ON pi.p_partkey = ps.ps_partkey
JOIN supplier_info si ON si.s_suppkey = ps.ps_suppkey
WHERE c.c_acctbal >= (
    SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = 'BUILDING'
) AND
    EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_custkey = c.c_custkey
        HAVING SUM(o.o_totalprice) > 10000
    )
GROUP BY c.c_name, c.c_acctbal
ORDER BY COALESCE(total_sales, 0) DESC, nation_count;
