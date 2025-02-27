WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 5000
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
final_summary AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_totalprice, ps.p_name, ps.ps_supplycost, lis.total_revenue 
    FROM customer_order co
    JOIN line_item_summary lis ON co.o_orderkey = lis.l_orderkey
    JOIN supplier_part ps ON ps.ps_supplycost < co.o_totalprice
)
SELECT f.c_custkey, f.c_name, f.o_orderkey, f.o_totalprice, f.p_name, f.ps_supplycost, f.total_revenue
FROM final_summary f
WHERE f.total_revenue > 1000
ORDER BY f.o_totalprice DESC, f.total_revenue ASC
LIMIT 100;
