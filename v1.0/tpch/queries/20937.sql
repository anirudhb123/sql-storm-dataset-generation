WITH RECURSIVE SupplierTree AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, st.level + 1
    FROM supplier sp
    JOIN SupplierTree st ON sp.s_suppkey = st.s_nationkey
), 
PartCost AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    WHERE ps.ps_supplycost > 0
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           pc.total_cost,
           RANK() OVER (ORDER BY pc.total_cost DESC) AS cost_rank
    FROM part p
    LEFT JOIN PartCost pc ON p.p_partkey = pc.ps_partkey
),
HighValueParts AS (
    SELECT r.p_partkey,
           r.p_name,
           r.total_cost
    FROM RankedParts r
    WHERE r.cost_rank <= 5
)
SELECT n.n_name AS nation_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END), 0) AS total_returns,
       HV.total_cost AS highest_part_cost
FROM nation n
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
JOIN HighValueParts HV ON HV.p_partkey = l.l_partkey
LEFT JOIN SupplierTree st ON st.s_nationkey = n.n_nationkey
WHERE n.n_name IS NOT NULL 
  AND (l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' OR l.l_shipdate IS NULL)
GROUP BY n.n_name, HV.total_cost
HAVING AVG(c.c_acctbal) > 1000
ORDER BY customer_count DESC, total_returns DESC;