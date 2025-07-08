
WITH RECURSIVE random_supplier AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM random_supplier rs
    JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n ORDER BY RANDOM() LIMIT 1) 
    WHERE s.s_acctbal < rs.s_acctbal
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -1, '1998-10-01'::DATE) 
    AND o.o_totalprice > 0
),
string_aggregates AS (
    SELECT n.n_name,
           LISTAGG(s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
part_summary AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING SUM(ps.ps_availqty * ps.ps_supplycost) > 1000
)
SELECT p.p_name, ps.total_value, ps.unique_suppliers, 
       COALESCE(sa.suppliers, 'No suppliers') AS suppliers,
       ro.price_rank
FROM part_summary ps
JOIN part p ON ps.p_partkey = p.p_partkey
LEFT JOIN string_aggregates sa ON sa.n_name = 'ASIA'
JOIN ranked_orders ro ON ro.o_orderkey = (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_totalprice = (SELECT MAX(o2.o_totalprice) 
                             FROM orders o2 
                             WHERE o2.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31') 
    LIMIT 1
)
WHERE ps.total_value IS NOT NULL
AND (ps.unique_suppliers IS NULL OR ps.unique_suppliers < 5)
ORDER BY ps.total_value DESC 
LIMIT 10;
