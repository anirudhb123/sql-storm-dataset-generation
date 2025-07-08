WITH supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, ps.ps_availqty, ps.ps_supplycost, ps.ps_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000
), relevant_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, o.o_shippriority
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'P')
      AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
), complete_data AS (
    SELECT sp.s_name, sp.p_name, sp.p_brand, ro.o_orderkey, ro.o_totalprice, ls.total_price
    FROM supplier_parts sp
    JOIN relevant_orders ro ON ro.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand LIKE 'Brand%')
    )
    JOIN lineitem_summary ls ON ro.o_orderkey = ls.l_orderkey
)
SELECT c.c_name, c.c_address, c.c_mktsegment, cd.s_name, cd.p_name, cd.o_orderkey, cd.total_price
FROM complete_data cd
JOIN customer c ON c.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey = cd.o_orderkey
)
ORDER BY cd.total_price DESC, c.c_name ASC
LIMIT 50;