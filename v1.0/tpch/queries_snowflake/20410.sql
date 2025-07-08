
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
NationRegions AS (
    SELECT n.n_nationkey, 
           n.n_name AS nation_name, 
           r.r_name AS region_name,
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT nr.region_name, 
       nr.nation_name, 
       COALESCE(AVG(rs.total_supply_cost), 0) AS avg_supply_cost,
       LISTAGG(rs.s_name, ', ') WITHIN GROUP (ORDER BY rs.s_name) AS supplier_names,
       NTILE(3) OVER (PARTITION BY nr.region_name ORDER BY COALESCE(AVG(rs.total_supply_cost), 0)) AS supply_cost_tier
FROM NationRegions nr
LEFT JOIN RankedSuppliers rs ON nr.n_nationkey = rs.s_suppkey
WHERE nr.customer_count > 0
GROUP BY nr.region_name, nr.nation_name
HAVING AVG(rs.total_supply_cost) IS NOT NULL AND 
       MAX(nr.customer_count) BETWEEN 1 AND 250
ORDER BY nr.region_name, supply_cost_tier;
