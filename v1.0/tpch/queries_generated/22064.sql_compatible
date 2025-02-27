
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), TotalCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
), FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE 
               WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
               WHEN p.p_size BETWEEN 11 AND 25 THEN 'Medium'
               ELSE 'Large' 
           END AS size_category,
           COALESCE(SUM(l.l_discount), 0) AS total_discount
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COALESCE(SUM(l.l_discount), 0) IS NULL OR COALESCE(SUM(l.l_discount), 0) < 5
), DistinctRegion AS (
    SELECT DISTINCT r.r_regionkey, r.r_name
    FROM region r
    WHERE r.r_name LIKE 'Asia%'
), FinalData AS (
    SELECT f.p_partkey, f.p_name, f.size_category, COALESCE(tc.total_cost, 0) AS total_cost,
           SUM(r.r_regionkey) OVER (PARTITION BY f.size_category) AS region_sum
    FROM FilteredParts f
    LEFT JOIN TotalCosts tc ON f.p_partkey = tc.ps_partkey
    LEFT JOIN DistinctRegion r ON r.r_regionkey IS NOT NULL
)
SELECT fd.p_partkey, fd.p_name, fd.size_category, fd.total_cost,
       CASE WHEN fd.total_cost > 1000 THEN 'Expensive'
            WHEN fd.total_cost BETWEEN 500 AND 1000 THEN 'Average'
            ELSE 'Cheap' END AS cost_category
FROM FinalData fd
WHERE EXISTS (
    SELECT 1
    FROM RankedSuppliers rs
    WHERE rs.rank = 1 AND rs.s_acctbal > 5000
)
ORDER BY fd.total_cost DESC, fd.p_partkey ASC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM FinalData) / 2;
