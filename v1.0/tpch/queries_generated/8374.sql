WITH recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY o.o_orderkey, o.o_orderdate
),
ranked_partsuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
top_suppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           ps.ps_supplycost, rps.s_name
    FROM ranked_partsuppliers rps
    WHERE rps.supplier_rank <= 3
),
regional_summary AS (
    SELECT n.n_name AS nation, r.r_name AS region, SUM(tv.total_revenue) AS total_revenue
    FROM recent_orders tv
    JOIN customer c ON tv.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT t.s_name AS supplier_name, t.ps_partkey AS part_key, t.ps_availqty AS available_quantity,
       t.ps_supplycost AS supply_cost, rs.nation, rs.region, rs.total_revenue
FROM top_suppliers t
JOIN regional_summary rs ON rs.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT MAX(o.o_custkey) FROM orders o)))
ORDER BY rs.total_revenue DESC, t.ps_supplycost ASC;
