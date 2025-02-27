WITH RECURSIVE region_nation AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    UNION ALL
    SELECT rn.r_regionkey, rn.r_name, n.n_nationkey, n.n_name
    FROM region_nation rn
    JOIN nation n ON rn.r_regionkey = n.n_regionkey
    WHERE rn.n_nationkey <> n.n_nationkey
), ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, COUNT(l.l_orderkey) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' 
      AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT rn.r_name, ns.n_name, ps.p_name, ps.total_available,
       SUM(os.total_order_value) AS total_sales,
       AVG(os.line_count) AS avg_lines_per_order, 
       COALESCE(MAX(rs.s_name), 'No Supplier') AS top_supplier
FROM region_nation rn
JOIN part_summary ps ON rn.n_nationkey = ps.p_partkey
LEFT JOIN ranked_suppliers rs ON rs.rank = 1
LEFT JOIN order_summary os ON os.o_custkey = rn.n_nationkey
WHERE ps.total_available > 0
GROUP BY rn.r_name, ns.n_name, ps.p_name
HAVING SUM(os.total_order_value) > 1000
ORDER BY total_sales DESC, avg_lines_per_order ASC;
