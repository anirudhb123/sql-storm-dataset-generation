WITH RECURSIVE nation_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ns.level + 1
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    INNER JOIN nation_suppliers ns ON s.s_nationkey = ns.s_nationkey
    WHERE ns.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
      AND o.o_totalprice IS NOT NULL
),
expensive_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) + STDDEV(p2.p_retailprice)
        FROM part p2
    ) AND p.p_type LIKE 'bolt%'
),
combined_data AS (
    SELECT cs.c_custkey, cs.c_name,
           ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.o_totalprice DESC) AS rn
    FROM customer_orders cs
    JOIN partsupp ps ON cs.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (SELECT ep.p_partkey FROM expensive_parts ep)
    )
),
final_selection AS (
    SELECT nd.s_suppkey, nd.s_name, cd.c_custkey, cd.c_name,
           cd.ps_partkey, cd.ps_availqty,
           COALESCE(cd.ps_supplycost, 0) * 0.9 AS adjusted_supplycost
    FROM nation_suppliers nd
    FULL OUTER JOIN combined_data cd ON nd.s_nationkey = cd.c_custkey
    WHERE nd.level < 3 OR cd.ps_availqty IS NULL
    ORDER BY adjusted_supplycost DESC
)
SELECT DISTINCT fs.s_suppkey, fs.s_name, fs.c_custkey, fs.c_name,
       fs.adjusted_supplycost,
       CASE WHEN fs.adjusted_supplycost IS NULL THEN 'No Supply Cost' ELSE 'With Supply Cost' END AS supply_cost_status
FROM final_selection fs
WHERE fs.adjusted_supplycost > (SELECT AVG(adjusted_supplycost) FROM final_selection)
   OR fs.c_name LIKE '%James%'
ORDER BY fs.s_suppkey, fs.c_name;
