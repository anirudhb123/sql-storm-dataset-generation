WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_acctbal, 1 AS order_level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_acctbal, oh.order_level + 1
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'F' AND oh.order_level < 5
),
supplier_performance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sale_price,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, 
           oh.c_acctbal, sp.total_cost,
           ROW_NUMBER() OVER (PARTITION BY oh.o_orderdate ORDER BY oh.o_totalprice DESC) AS rank
    FROM order_hierarchy oh
    LEFT JOIN supplier_performance sp ON sp.part_count > 0
)
SELECT os.o_orderkey, os.o_orderdate, os.o_totalprice,
       CASE 
           WHEN os.total_cost IS NULL THEN 'No Supplier'
           ELSE 'Supplier Found'
       END AS supplier_status,
       os.c_acctbal, 
       CASE 
           WHEN os.rank <= 10 THEN 'Top Order'
           ELSE 'Regular Order'
       END AS order_category
FROM order_summary os
WHERE os.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) OR os.c_acctbal IS NULL
ORDER BY os.o_orderdate DESC, os.o_totalprice DESC;
