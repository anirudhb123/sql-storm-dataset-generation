WITH total_supplier_cost AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
top_suppliers AS (
    SELECT s.s_name, s.s_nationkey, t.total_cost
    FROM supplier s
    JOIN total_supplier_cost t ON s.s_suppkey = t.ps_suppkey
    ORDER BY t.total_cost DESC
    LIMIT 10
),
nation_details AS (
    SELECT n.n_name, n.n_regionkey
    FROM nation n
    WHERE n.n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier)
),
supplier_region AS (
    SELECT ts.s_name, nd.n_name, r.r_name
    FROM top_suppliers ts
    JOIN nation_details nd ON ts.s_nationkey = nd.n_nationkey
    JOIN region r ON nd.n_regionkey = r.r_regionkey
)
SELECT sr.r_name, COUNT(sr.s_name) AS supplier_count, SUM(ts.total_cost) AS total_supplier_cost
FROM supplier_region sr
JOIN top_suppliers ts ON sr.s_name = ts.s_name
GROUP BY sr.r_name
ORDER BY total_supplier_cost DESC;
