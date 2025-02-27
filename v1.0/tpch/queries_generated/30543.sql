WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
part_supply AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
current_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
top_orders AS (
    SELECT co.o_orderkey, co.o_orderdate, co.o_totalprice, r.r_name, co.order_rank
    FROM current_orders co
    LEFT JOIN nation n ON co.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE co.order_rank <= 5
)
SELECT 
    shp.s_name AS supplier_name,
    pp.p_name AS part_name,
    ps.total_supply_cost,
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice
FROM supplier_hierarchy shp
FULL OUTER JOIN part_supply ps ON shp.s_suppkey = ps.p_partkey
LEFT JOIN top_orders to ON ps.p_partkey = to.o_orderkey
WHERE ps.total_supply_cost IS NOT NULL OR to.o_orderkey IS NULL
ORDER BY ps.total_supply_cost DESC, to.o_totalprice DESC
LIMIT 100;
