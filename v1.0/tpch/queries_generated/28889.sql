WITH SupplierDetails AS (
    SELECT s.s_name, s.s_address, n.n_name AS nation_name, r.r_name AS region_name, s.s_acctbal,
           CONCAT(s.s_name, ' - ', n.n_name, ' (', r.r_name, ')') AS full_details
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplied AS (
    SELECT p.p_name, ps.ps_supplycost, ps.ps_availqty, s.s_suppkey, s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedData AS (
    SELECT ps.p_name, AVG(ps.ps_supplycost) AS avg_supplycost, SUM(ps.ps_availqty) AS total_availqty, 
           COUNT(DISTINCT ps.s_suppkey) AS unique_suppliers
    FROM PartSupplied ps
    GROUP BY ps.p_name
)
SELECT ad.p_name, 
       ad.avg_supplycost, 
       ad.total_availqty, 
       ad.unique_suppliers,
       RANK() OVER (ORDER BY ad.avg_supplycost DESC) AS rank_by_cost
FROM AggregatedData ad
WHERE ad.total_availqty > (
    SELECT AVG(total_availqty)
    FROM AggregatedData
)
ORDER BY ad.rank_by_cost;
